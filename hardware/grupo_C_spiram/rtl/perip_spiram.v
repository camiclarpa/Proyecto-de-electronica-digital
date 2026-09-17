`timescale 1ns/1ps

// perip_spiram -- controlador de RAM externa por SPI (modo 0, CPOL=0
// CPHA=0), mapeada en el bus de perifericos del SoC.
//
// "addr" es el OFFSET LOCAL dentro de la ventana de este periferico
// (0x410000-0x41FFFF, ver ../../../docs/mapa_memoria.md) -- el
// decodificador del SoC resta la base antes de conectarlo aqui, igual
// que exige la convencion del curso (ver README.md de esta carpeta).
//
// A diferencia de perip_uart (registros simples, respuesta en 1
// ciclo), este modulo controla una memoria EXTERNA por un bus serial:
// cada acceso de datos dispara una transaccion SPI real que tarda
// varios ciclos de "clk" del sistema -- el software debe sondear el
// bit "busy" de SPIRAM_STATUS (ver protocolo en diagramas/README.md).

module perip_spiram (
    input  wire        clk,
    input  wire         rst,
    input  wire [31:0] d_in,
    input  wire        cs,
    input  wire [15:0] addr,   // offset dentro de la ventana de 64KB (0x0000-0xFFFF)
    input  wire        rd,
    input  wire        wr,
    output reg  [31:0] d_out,
    // pines fisicos hacia el chip de RAM SPI externo
    output reg          cs_n,
    output reg          sclk,
    output reg          mosi,
    input  wire          miso
);
    localparam [15:0] ADDR_STATUS = 16'hFFFC; // ultimo word de la ventana de 64KB

    // Comandos tipo SPI SRAM (misma familia usada en el esqueleto original)
    localparam [7:0] CMD_WRITE = 8'h02;
    localparam [7:0] CMD_READ  = 8'h03;

    localparam [1:0] IDLE      = 2'd0,
                      XFER_HDR  = 2'd1, // 32 bits: comando(8) + direccion externa(24)
                      XFER_DATA = 2'd2, // 32 bits: dato (escritura) o datos entrantes (lectura)
                      DONE      = 2'd3;

    reg [1:0]  state;
    reg [6:0]  bit_count;   // hasta 32
    reg [31:0] shift_out;
    reg [31:0] shift_in;
    reg        op_we;       // 1 = la transaccion en curso es una escritura
    reg        busy;
    reg [31:0] data_reg;    // ultimo dato leido, valido cuando busy vuelve a 0

    // direccion externa de 24 bits: la ventana de 64KB se mapea 1:1,
    // byte a byte, sobre las primeras 64KB del chip de RAM externo.
    wire [23:0] ext_addr = {8'h00, addr};

    always @(posedge clk) begin
        if (rst) begin
            state     <= IDLE;
            cs_n      <= 1'b1;
            sclk      <= 1'b0;
            mosi      <= 1'b0;
            busy      <= 1'b0;
            bit_count <= 7'd0;
        end else begin
            case (state)
                IDLE: begin
                    cs_n <= 1'b1;
                    if (cs && (rd || wr) && addr != ADDR_STATUS && !busy) begin
                        op_we     <= wr;
                        shift_out <= {wr ? CMD_WRITE : CMD_READ, ext_addr};
                        bit_count <= 7'd0;
                        cs_n      <= 1'b0;
                        busy      <= 1'b1;
                        // sclk arranca en 1 (no en 0) para que el primer
                        // ciclo dentro de XFER_HDR sea un flanco de bajada
                        // real (saca el primer bit) en vez de muestrear el
                        // valor viejo de mosi -- mismo mecanismo por el que
                        // las transiciones HDR->DATA ya se autocorrigen
                        // (heredan sclk=1 del ultimo ciclo de la fase previa).
                        sclk      <= 1'b1;
                        state     <= XFER_HDR;
                    end
                end

                XFER_HDR: begin
                    sclk <= ~sclk;
                    if (sclk) begin // flanco de bajada: el maestro cambia mosi
                        mosi      <= shift_out[31];
                        shift_out <= {shift_out[30:0], 1'b0};
                    end else begin // flanco de subida: se cuenta el bit ya muestreado
                        bit_count <= bit_count + 1'b1;
                        if (bit_count == 7'd31) begin
                            bit_count <= 7'd0;
                            shift_out <= d_in; // se precarga para la fase de datos (si es escritura)
                            state     <= XFER_DATA;
                        end
                    end
                end

                XFER_DATA: begin
                    sclk <= ~sclk;
                    if (op_we) begin
                        if (sclk) begin
                            mosi      <= shift_out[31];
                            shift_out <= {shift_out[30:0], 1'b0};
                        end else begin
                            bit_count <= bit_count + 1'b1;
                            if (bit_count == 7'd31) state <= DONE;
                        end
                    end else begin
                        if (!sclk) begin // flanco de subida: se muestrea miso
                            shift_in  <= {shift_in[30:0], miso};
                            bit_count <= bit_count + 1'b1;
                            if (bit_count == 7'd31) state <= DONE;
                        end
                    end
                end

                DONE: begin
                    cs_n <= 1'b1;
                    busy <= 1'b0;
                    if (!op_we) data_reg <= shift_in;
                    state <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end

    // ---- Interfaz de registros (lado del bus del SoC) ----
    always @(*) begin
        d_out = 32'd0;
        if (cs && rd) begin
            if (addr == ADDR_STATUS)
                d_out = {31'd0, busy};
            else
                d_out = data_reg; // ultimo dato capturado (valido cuando busy==0)
        end
    end
endmodule
