`timescale 1ns/1ps

// perip_uart — UART 8N1, mapeada en el bus de perifericos del SoC.
//
// "addr" es el OFFSET LOCAL dentro de la ventana de este periferico
// (0x400000-0x40FFFF, ver ../../../docs/mapa_memoria.md) -- el
// decodificador del SoC resta la base antes de conectarlo aqui, igual
// que exige la convencion del curso (ver README.md de esta carpeta).

module perip_uart #(
    parameter CLK_FREQ = 25000000,
    parameter BAUD     = 57600
) (
    input  wire        clk,
    input  wire        rst,
    input  wire [31:0] d_in,
    input  wire        cs,
    input  wire [3:0]  addr,
    input  wire        rd,
    input  wire        wr,
    output reg  [31:0] d_out,
    output reg          tx,
    input  wire          rx
);
    localparam ADDR_DATA   = 4'h0; // 0x00 - UART_DATA
    localparam ADDR_STATUS = 4'h4; // 0x04 - UART_STATUS
    localparam integer DIV = CLK_FREQ / BAUD;

    // ---- Transmisor: registro de desplazamiento, LSB primero ----
    reg [12:0] tx_count;
    reg [3:0]  tx_bit;
    reg [9:0]  tx_shift;
    reg        tx_busy;

    always @(posedge clk) begin
        if (rst) begin
            tx <= 1'b1; tx_busy <= 1'b0; tx_count <= 0; tx_bit <= 0;
        end else if (cs && wr && addr == ADDR_DATA && !tx_busy) begin
            tx_shift <= {1'b1, d_in[7:0], 1'b0}; // stop, datos, start
            tx_busy  <= 1'b1; tx_count <= 0; tx_bit <= 0;
        end else if (tx_busy) begin
            if (tx_count == DIV-1) begin
                tx_count <= 0;
                tx       <= tx_shift[0];
                tx_shift <= {1'b1, tx_shift[9:1]};
                tx_bit   <= tx_bit + 1'b1;
                if (tx_bit == 4'd9) tx_busy <= 1'b0;
            end else tx_count <= tx_count + 1'b1;
        end
    end

    // ---- Receptor: detecta flanco de bajada del start, muestrea al centro de cada bit ----
    reg [12:0] rx_count;
    reg [3:0]  rx_bit;
    reg [7:0]  rx_shift;
    reg        rx_busy;
    reg [7:0]  rx_data;
    reg        rx_valid;
    reg        rx_prev;

    always @(posedge clk) begin
        if (rst) begin
            rx_busy <= 1'b0; rx_valid <= 1'b0; rx_prev <= 1'b1;
        end else begin
            rx_prev <= rx;
            if (cs && rd && addr == ADDR_DATA) rx_valid <= 1'b0; // se limpia al leer

            if (!rx_busy) begin
                if (rx_prev && !rx) begin // flanco de bajada = bit de start
                    rx_busy  <= 1'b1;
                    rx_count <= DIV/2; // muestrear al CENTRO del primer bit de dato
                    rx_bit   <= 0;
                end
            end else if (rx_count == DIV-1) begin
                rx_count <= 0;
                rx_shift <= {rx, rx_shift[7:1]};
                rx_bit   <= rx_bit + 1'b1;
                if (rx_bit == 4'd7) begin
                    rx_busy  <= 1'b0;
                    rx_data  <= {rx, rx_shift[7:1]};
                    rx_valid <= 1'b1;
                end
            end else rx_count <= rx_count + 1'b1;
        end
    end

    // ---- Interfaz de registros (lado del bus del SoC) ----
    always @(*) begin
        d_out = 32'd0;
        if (cs && rd) begin
            case (addr)
                ADDR_DATA:   d_out = {24'd0, rx_data};
                ADDR_STATUS: d_out = {30'd0, rx_valid, tx_busy};
                default:     d_out = 32'd0;
            endcase
        end
    end
endmodule
