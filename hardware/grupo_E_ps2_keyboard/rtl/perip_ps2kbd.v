`timescale 1ns/1ps

// perip_ps2kbd -- Teclado PS/2 (Scan Code Set 2), mapeado en el bus de
// perifericos del SoC.
//
// "addr" es el OFFSET LOCAL dentro de la ventana de este periferico
// (0x430000-0x43FFFF, ver ../../../docs/mapa_memoria.md) -- el
// decodificador del SoC resta la base antes de conectarlo aqui, igual
// que exige la convencion del curso (ver README.md de esta carpeta).
//
// ps2_clk/ps2_data llegan directo del conector PS/2 externo (asincronos
// al reloj del sistema) -- este modulo incluye su propio sincronizador
// de doble flip-flop antes de usarlos, para evitar metaestabilidad.
//
// KBD_DATA y KBD_STATUS son de SOLO LECTURA (el teclado es quien manda
// los datos) -- "wr" se deja en la interfaz por consistencia con el bus
// del SoC, pero este modulo no lo usa.

module perip_ps2kbd (
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
    localparam ADDR_DATA   = 4'h0; // 0x00 - KBD_DATA
    localparam ADDR_STATUS = 4'h4; // 0x04 - KBD_STATUS

    // ---- Sincronizador de doble flip-flop (evita metaestabilidad) ----
    reg ps2_clk_ff1, ps2_clk_ff2;
    reg ps2_data_ff1, ps2_data_ff2;
    always @(posedge clk) begin
        ps2_clk_ff1  <= ps2_clk;
        ps2_clk_ff2  <= ps2_clk_ff1;
        ps2_data_ff1 <= ps2_data;
        ps2_data_ff2 <= ps2_data_ff1;
    end

    // ---- Receptor: 11 bits (start=0, 8 datos LSB primero, paridad impar, stop=1) ----
    reg [3:0]  bit_count;
    reg [10:0] shift_reg;
    reg        ps2_clk_prev;
    reg        pending_release;

    reg [7:0] scancode;
    reg       key_release;
    reg       kbd_valid;

    // Valor COMBINACIONAL de "shift_reg tras este bit" -- imprescindible
    // para poder leer el byte completo en el mismo ciclo en que llega el
    // bit 11 (el stop bit): "shift_reg" en si (registrado) todavia no
    // refleja el bit que se esta capturando en este flanco.
    wire [10:0] shift_reg_next = {ps2_data_ff2, shift_reg[10:1]};

    always @(posedge clk) begin
        if (rst) begin
            bit_count <= 0; shift_reg <= 0; ps2_clk_prev <= 1'b1;
            pending_release <= 1'b0; scancode <= 0; key_release <= 0;
            kbd_valid <= 1'b0;
        end else begin
            ps2_clk_prev <= ps2_clk_ff2;
            if (cs && rd && addr == ADDR_DATA) kbd_valid <= 1'b0; // se limpia al leer

            if (ps2_clk_prev && !ps2_clk_ff2) begin // flanco de bajada real del teclado
                shift_reg <= shift_reg_next;
                bit_count <= bit_count + 1'b1;
                if (bit_count == 4'd10) begin
                    bit_count <= 0;
                    // shift_reg_next[8:1] = los 8 bits de datos (ya sin start/parity/stop)
                    if (shift_reg_next[8:1] == 8'hF0) begin
                        pending_release <= 1'b1; // el SIGUIENTE byte es el que se solto
                    end else begin
                        scancode    <= shift_reg_next[8:1];
                        key_release <= pending_release;
                        pending_release <= 1'b0;
                        kbd_valid   <= 1'b1;
                    end
                end
            end
        end
    end

    // ---- Interfaz de registros (lado del bus del SoC) ----
    always @(*) begin
        d_out = 32'd0;
        if (cs && rd) begin
            case (addr)
                ADDR_DATA:   d_out = {23'd0, key_release, scancode};
                ADDR_STATUS: d_out = {31'd0, kbd_valid};
                default:     d_out = 32'd0;
            endcase
        end
    end
endmodule
