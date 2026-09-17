`timescale 1ns/1ps

// perip_i2c -- maestro I2C modo estandar (100kHz), mapeado en el bus de
// perifericos del SoC. Transferencias de UN byte (direccion + 1 dato).
//
// "addr" es el OFFSET LOCAL dentro de la ventana de este periferico
// (0x460000-0x46FFFF, ver ../../../docs/mapa_memoria.md) -- el
// decodificador del SoC resta la base antes de conectarlo aqui, igual
// que exige la convencion del curso (ver README.md de esta carpeta).
//
// scl/sda son colector abierto real: este modulo solo puede llevarlas a
// 0 (oe=1) o liberarlas (oe=0, alta impedancia) para que el pull-up
// externo las suba a 1. Esto es lo que permite CLOCK STRETCHING: tras
// liberar SCL (fase PH_RISE), el maestro espera a leer SCL=1 de vuelta
// antes de seguir -- si el esclavo la retiene en 0 para pedir mas
// tiempo, el maestro simplemente espera en esa fase.

module perip_i2c #(
    parameter CLK_FREQ = 25000000,
    parameter I2C_FREQ = 100000
) (
    input  wire        clk,
    input  wire        rst,
    input  wire [31:0] d_in,
    input  wire        cs,
    input  wire [3:0]  addr,
    input  wire        rd,
    input  wire        wr,
    output reg  [31:0] d_out,
    inout  wire         scl,
    inout  wire         sda
);
    localparam ADDR_ADDR   = 4'h0; // 0x00 - I2C_ADDR   (W)
    localparam ADDR_DATA   = 4'h4; // 0x04 - I2C_DATA   (R/W)
    localparam ADDR_CTRL   = 4'h8; // 0x08 - I2C_CTRL   (W)  bit0=start, bit1=rw
    localparam ADDR_STATUS = 4'hC; // 0x0C - I2C_STATUS (R)  bit0=busy, bit1=ack_error

    localparam integer DIV = CLK_FREQ / (I2C_FREQ * 4); // 1 fase de SCL = DIV ciclos de clk

    // ---- Registros direccionables desde el bus ----
    reg [6:0] slave_addr;
    reg       rw;          // 0 = escritura, 1 = lectura
    reg [7:0] data_reg;    // escribir: dato a mandar. leer: ultimo dato recibido
    reg       busy;
    reg       ack_error;

    // ---- Lineas fisicas (colector abierto: 1=drive low, 0=liberar) ----
    // Se inicializan en 0 explicitamente: sin esto, el registro arranca en
    // 'X' y la transicion X->0 al aplicar el primer reset cuenta como un
    // flanco de bajada valido en simulacion (LRM de Verilog), lo que puede
    // disparar logica de testbench sensible a negedge(scl) antes de tiempo.
    reg scl_oe = 1'b0, sda_oe = 1'b0;
    assign scl = scl_oe ? 1'b0 : 1'bz;
    assign sda = sda_oe ? 1'b0 : 1'bz;

    // ---- FSM principal ----
    localparam S_IDLE=0, S_START=1, S_BYTE=2, S_BYTE_ACK=3, S_RBYTE=4, S_RBYTE_ACK=5, S_STOP=6;
    reg [2:0]  state;
    localparam PH0=0, PH1=1, PH2=2, PH3=3;
    reg [1:0]  phase;
    reg [15:0] ph_cnt;
    reg [3:0]  bit_cnt;
    reg [7:0]  shift_tx;
    reg [7:0]  shift_rx;
    reg        byte_is_addr; // 1 mientras se manda direccion+RW, 0 en el byte de datos
    reg        start_req;
    reg        rw_latched;

    always @(posedge clk) begin
        if (rst) begin
            state <= S_IDLE; phase <= PH0; ph_cnt <= 0; bit_cnt <= 0;
            scl_oe <= 1'b0; sda_oe <= 1'b0;
            busy <= 1'b0; ack_error <= 1'b0; start_req <= 1'b0;
        end else begin
            // ---- Interfaz de registros (lado del bus del SoC) ----
            if (cs && wr) begin
                case (addr)
                    ADDR_ADDR: slave_addr <= d_in[6:0];
                    ADDR_DATA: if (!busy) data_reg <= d_in[7:0];
                    ADDR_CTRL: if (d_in[0] && !busy) begin
                        start_req <= 1'b1; rw_latched <= d_in[1];
                    end
                    default: ;
                endcase
            end

            case (state)
                // ---------------------------------------------------- IDLE
                S_IDLE: begin
                    scl_oe <= 1'b0; sda_oe <= 1'b0;
                    if (start_req) begin
                        start_req <= 1'b0; busy <= 1'b1; ack_error <= 1'b0;
                        rw <= rw_latched;
                        state <= S_START; phase <= PH0; ph_cnt <= 0;
                    end
                end
                // --------------------------------------------- START (S)
                // SCL alta (liberada) -> SDA baja -> SCL baja (listo para el primer bit)
                S_START: begin
                    case (phase)
                        PH0: begin // asegura bus liberado (SCL y SDA altas) antes de empezar
                            scl_oe <= 1'b0; sda_oe <= 1'b0;
                            if (ph_cnt == DIV) begin ph_cnt <= 0; phase <= PH1; end
                            else ph_cnt <= ph_cnt + 1'b1;
                        end
                        PH1: begin // condicion START: SDA baja con SCL en alto
                            sda_oe <= 1'b1;
                            if (ph_cnt == DIV) begin ph_cnt <= 0; phase <= PH2; end
                            else ph_cnt <= ph_cnt + 1'b1;
                        end
                        PH2: begin // baja SCL, listo para desplazar el primer bit
                            scl_oe <= 1'b1;
                            if (ph_cnt == DIV) begin
                                ph_cnt <= 0; bit_cnt <= 0; byte_is_addr <= 1'b1;
                                shift_tx <= {slave_addr, rw};
                                state <= S_BYTE; phase <= PH0;
                            end else ph_cnt <= ph_cnt + 1'b1;
                        end
                        default: ;
                    endcase
                end
                // --------------------------------------- BYTE (8 bits, MSB primero)
                // Usado tanto para direccion+RW como para el byte de datos en escritura.
                S_BYTE: begin
                    case (phase)
                        PH0: begin // setup: pone el bit en SDA con SCL todavia baja
                            sda_oe <= ~shift_tx[7];
                            if (ph_cnt == DIV) begin ph_cnt <= 0; phase <= PH1; end
                            else ph_cnt <= ph_cnt + 1'b1;
                        end
                        PH1: begin // libera SCL; espera a que suba de verdad (clock stretching)
                            scl_oe <= 1'b0;
                            if (scl == 1'b1) begin ph_cnt <= 0; phase <= PH2; end
                        end
                        PH2: begin // SCL alta y estable: mantenerla
                            if (ph_cnt == DIV) begin ph_cnt <= 0; phase <= PH3; end
                            else ph_cnt <= ph_cnt + 1'b1;
                        end
                        PH3: begin // baja SCL de nuevo, avanza al siguiente bit
                            scl_oe <= 1'b1;
                            if (ph_cnt == DIV) begin
                                ph_cnt <= 0;
                                shift_tx <= {shift_tx[6:0], 1'b0};
                                if (bit_cnt == 4'd7) begin
                                    state <= S_BYTE_ACK; phase <= PH0;
                                end else begin
                                    bit_cnt <= bit_cnt + 1'b1; phase <= PH0;
                                end
                            end else ph_cnt <= ph_cnt + 1'b1;
                        end
                    endcase
                end
                // ------------------------------------------- ACK del esclavo
                S_BYTE_ACK: begin
                    case (phase)
                        PH0: begin // libera SDA para que el esclavo maneje el ACK
                            sda_oe <= 1'b0;
                            if (ph_cnt == DIV) begin ph_cnt <= 0; phase <= PH1; end
                            else ph_cnt <= ph_cnt + 1'b1;
                        end
                        PH1: begin
                            scl_oe <= 1'b0;
                            if (scl == 1'b1) begin ph_cnt <= 0; phase <= PH2; end
                        end
                        PH2: begin // muestrea ACK/NACK (0=ACK, 1=NACK) a mitad de fase alta
                            if (ph_cnt == DIV/2) ack_error <= sda; // sda=1 => no hubo ACK
                            if (ph_cnt == DIV) begin ph_cnt <= 0; phase <= PH3; end
                            else ph_cnt <= ph_cnt + 1'b1;
                        end
                        PH3: begin
                            scl_oe <= 1'b1;
                            if (ph_cnt == DIV) begin
                                ph_cnt <= 0;
                                if (ack_error) begin
                                    state <= S_STOP; phase <= PH0;
                                end else if (byte_is_addr) begin
                                    byte_is_addr <= 1'b0;
                                    if (rw) begin
                                        bit_cnt <= 0; state <= S_RBYTE; phase <= PH0;
                                    end else begin
                                        bit_cnt <= 0; shift_tx <= data_reg;
                                        state <= S_BYTE; phase <= PH0;
                                    end
                                end else begin
                                    state <= S_STOP; phase <= PH0; // byte de datos ya escrito
                                end
                            end else ph_cnt <= ph_cnt + 1'b1;
                        end
                    endcase
                end
                // --------------------------------------- lectura de 1 byte del esclavo
                S_RBYTE: begin
                    case (phase)
                        PH0: begin // maestro libera SDA: quien maneja el dato es el esclavo
                            sda_oe <= 1'b0;
                            if (ph_cnt == DIV) begin ph_cnt <= 0; phase <= PH1; end
                            else ph_cnt <= ph_cnt + 1'b1;
                        end
                        PH1: begin
                            scl_oe <= 1'b0;
                            if (scl == 1'b1) begin ph_cnt <= 0; phase <= PH2; end
                        end
                        PH2: begin // muestrea el bit a mitad de fase alta
                            if (ph_cnt == DIV/2) shift_rx <= {shift_rx[6:0], sda};
                            if (ph_cnt == DIV) begin ph_cnt <= 0; phase <= PH3; end
                            else ph_cnt <= ph_cnt + 1'b1;
                        end
                        PH3: begin
                            scl_oe <= 1'b1;
                            if (ph_cnt == DIV) begin
                                ph_cnt <= 0;
                                if (bit_cnt == 4'd7) begin
                                    state <= S_RBYTE_ACK; phase <= PH0;
                                end else begin
                                    bit_cnt <= bit_cnt + 1'b1; phase <= PH0;
                                end
                            end else ph_cnt <= ph_cnt + 1'b1;
                        end
                    endcase
                end
                // ------------------------------- NACK del maestro (transferencia de 1 byte)
                S_RBYTE_ACK: begin
                    case (phase)
                        PH0: begin // NACK = no manejar SDA (queda en alto por el pull-up)
                            sda_oe <= 1'b0;
                            if (ph_cnt == DIV) begin ph_cnt <= 0; phase <= PH1; end
                            else ph_cnt <= ph_cnt + 1'b1;
                        end
                        PH1: begin
                            scl_oe <= 1'b0;
                            if (scl == 1'b1) begin ph_cnt <= 0; phase <= PH2; end
                        end
                        PH2: begin
                            if (ph_cnt == DIV) begin ph_cnt <= 0; phase <= PH3; end
                            else ph_cnt <= ph_cnt + 1'b1;
                        end
                        PH3: begin
                            scl_oe <= 1'b1;
                            if (ph_cnt == DIV) begin
                                ph_cnt <= 0; data_reg <= shift_rx;
                                state <= S_STOP; phase <= PH0;
                            end else ph_cnt <= ph_cnt + 1'b1;
                        end
                    endcase
                end
                // --------------------------------------------------- STOP (P)
                // SDA baja (con SCL baja) -> libera SCL -> libera SDA con SCL alta
                S_STOP: begin
                    case (phase)
                        PH0: begin
                            sda_oe <= 1'b1;
                            if (ph_cnt == DIV) begin ph_cnt <= 0; phase <= PH1; end
                            else ph_cnt <= ph_cnt + 1'b1;
                        end
                        PH1: begin
                            scl_oe <= 1'b0;
                            if (scl == 1'b1) begin ph_cnt <= 0; phase <= PH2; end
                        end
                        PH2: begin // condicion STOP: SDA sube con SCL en alto
                            sda_oe <= 1'b0;
                            if (ph_cnt == DIV) begin
                                ph_cnt <= 0; busy <= 1'b0; state <= S_IDLE; phase <= PH0;
                            end else ph_cnt <= ph_cnt + 1'b1;
                        end
                        default: ;
                    endcase
                end
                default: state <= S_IDLE;
            endcase
        end
    end

    // ---- Lectura de registros (lado del bus del SoC) ----
    always @(*) begin
        d_out = 32'd0;
        if (cs && rd) begin
            case (addr)
                ADDR_DATA:   d_out = {24'd0, data_reg};
                ADDR_STATUS: d_out = {30'd0, ack_error, busy};
                default:     d_out = 32'd0;
            endcase
        end
    end
endmodule
