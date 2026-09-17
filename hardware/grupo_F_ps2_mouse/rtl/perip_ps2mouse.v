`timescale 1ns/1ps

// perip_ps2mouse -- Mouse PS/2 (paquetes de 3 bytes), mapeado en el bus
// de perifericos del SoC.
//
// "addr" es el OFFSET LOCAL dentro de la ventana de este periferico
// (0x440000-0x44FFFF, ver ../../../docs/mapa_memoria.md) -- el
// decodificador del SoC resta la base antes de conectarlo aqui, igual
// que exige la convencion del curso (ver README.md de esta carpeta).
//
// Reutiliza la misma logica de receptor de bytes de 11 bits que
// perip_ps2kbd.v (protocolo de trama PS/2 identico a nivel de bits,
// incluido el sincronizador de doble flip-flop) -- lo que cambia es la
// capa de arriba: en vez de scancodes, se acumulan 3 bytes para formar
// un paquete de movimiento/botones.
//
// PENDIENTE (no implementado en este modulo): el comando de
// habilitacion 0xF4 que la FPGA debe TRANSMITIR hacia el mouse al
// arrancar para activar el modo streaming -- requiere que el modulo
// tambien sepa transmitir (el host toma el bus PS/2), no solo recibir.
// Ver README.md, seccion "Estado".

module perip_ps2mouse (
    input  wire        clk,
    input  wire        rst,
    input  wire [31:0] d_in,
    input  wire        cs,
    input  wire [3:0]  addr,
    input  wire        rd,
    input  wire        wr,
    output reg  [31:0] d_out,
    input  wire        ps2_clk,
    input  wire        ps2_data
);
    localparam ADDR_STATUS = 4'h0; // 0x00 - MOUSE_STATUS
    localparam ADDR_DX     = 4'h4; // 0x04 - MOUSE_DX
    localparam ADDR_DY     = 4'h8; // 0x08 - MOUSE_DY
    localparam ADDR_VALID  = 4'hC; // 0x0C - MOUSE_VALID

    // ---- Sincronizador de doble flip-flop (evita metaestabilidad) ----
    reg ps2_clk_ff1, ps2_clk_ff2;
    reg ps2_data_ff1, ps2_data_ff2;
    always @(posedge clk) begin
        ps2_clk_ff1  <= ps2_clk;
        ps2_clk_ff2  <= ps2_clk_ff1;
        ps2_data_ff1 <= ps2_data;
        ps2_data_ff2 <= ps2_data_ff1;
    end

    // ---- Receptor de bytes: 11 bits (start=0, 8 datos LSB primero, paridad impar, stop=1) ----
    reg [3:0]  bit_count;
    reg [10:0] shift_reg;
    reg        ps2_clk_prev;
    reg [7:0]  byte_in;
    reg        byte_ready;

    // Valor COMBINACIONAL de "shift_reg tras este bit" -- imprescindible
    // para poder leer el byte completo en el mismo ciclo en que llega el
    // bit 11 (el stop bit): "shift_reg" en si (registrado) todavia no
    // refleja el bit que se esta capturando en este flanco.
    wire [10:0] shift_reg_next = {ps2_data_ff2, shift_reg[10:1]};

    always @(posedge clk) begin
        if (rst) begin
            bit_count <= 0; shift_reg <= 0; ps2_clk_prev <= 1'b1;
            byte_in <= 0; byte_ready <= 1'b0;
        end else begin
            ps2_clk_prev <= ps2_clk_ff2;
            byte_ready <= 1'b0;

            if (ps2_clk_prev && !ps2_clk_ff2) begin // flanco de bajada real del mouse
                shift_reg <= shift_reg_next;
                bit_count <= bit_count + 1'b1;
                if (bit_count == 4'd10) begin
                    bit_count  <= 0;
                    byte_in    <= shift_reg_next[8:1]; // 8 bits de datos, sin start/parity/stop
                    byte_ready <= 1'b1;
                end
            end
        end
    end

    // ---- Acumulador de paquete: 3 bytes -> status/dx/dy ----
    reg [1:0]        byte_index;
    reg [7:0]         status_byte;
    reg signed [8:0]  dx, dy;
    reg               packet_valid;

    always @(posedge clk) begin
        if (rst) begin
            byte_index <= 0; status_byte <= 0; dx <= 0; dy <= 0; packet_valid <= 1'b0;
        end else begin
            if (cs && rd && addr == ADDR_VALID) packet_valid <= 1'b0; // se limpia al leer

            if (byte_ready) begin
                case (byte_index)
                    2'd0: status_byte <= byte_in;
                    2'd1: dx <= {status_byte[4], byte_in}; // bit4 de status = X sign
                    2'd2: begin
                        dy <= {status_byte[5], byte_in}; // bit5 de status = Y sign
                        packet_valid <= 1'b1;
                    end
                endcase
                byte_index <= (byte_index == 2'd2) ? 2'd0 : byte_index + 1'b1;
            end
        end
    end

    // ---- Interfaz de registros (lado del bus del SoC) ----
    always @(*) begin
        d_out = 32'd0;
        if (cs && rd) begin
            case (addr)
                ADDR_STATUS: d_out = {24'd0, status_byte};
                ADDR_DX:     d_out = {{23{dx[8]}}, dx}; // sign-extend a 32 bits
                ADDR_DY:     d_out = {{23{dy[8]}}, dy}; // sign-extend a 32 bits
                ADDR_VALID:  d_out = {31'd0, packet_valid};
                default:     d_out = 32'd0;
            endcase
        end
    end
endmodule
