`timescale 1ns/1ps

// perip_nes -- lee 8 controles NES compartiendo LATCH y CLOCK, con una
// linea DATA independiente por control (data[0]..data[7]).
//
// "addr" es el OFFSET LOCAL dentro de la ventana de este periferico
// (0x450000-0x45FFFF, ver ../../../docs/mapa_memoria.md) -- el
// decodificador del SoC resta la base antes de conectarlo aqui, igual
// que exige la convencion del curso (ver README.md de esta carpeta).

module perip_nes #(
    parameter HALF_PERIOD = 300 // ciclos de clk por cada fase Latch/Clock
                                 // (a 25MHz, 300 ciclos = 12us, como pide el protocolo real)
) (
    input  wire        clk,
    input  wire        rst,
    input  wire [31:0] d_in,
    input  wire        cs,
    input  wire [4:0]  addr,
    input  wire        rd,
    input  wire        wr,
    output reg  [31:0] d_out,
    output reg          latch = 1'b0,
    output reg          clock_out = 1'b0,
    input  wire [7:0]   data       // data[0]=control1 (P1) ... data[7]=control8 (P8)
);
    localparam ADDR_P1 = 5'h00, ADDR_P2 = 5'h04, ADDR_P3 = 5'h08, ADDR_P4 = 5'h0C;
    localparam ADDR_P5 = 5'h10, ADDR_P6 = 5'h14, ADDR_P7 = 5'h18, ADDR_P8 = 5'h1C;

    // 8 registros de 8 bits, uno por control. bit0=A,1=B,2=Select,3=Start,
    // 4=Up,5=Down,6=Left,7=Right (orden real del shift register 4021).
    reg [7:0] buttons [0:7];

    localparam LATCH_HIGH=2'd0, LATCH_LOW=2'd1, CLOCK_HIGH=2'd2, CLOCK_LOW=2'd3;
    reg [1:0]  state;
    reg [15:0] counter;
    reg [2:0]  bit_index;
    integer i;

    always @(posedge clk) begin
        if (rst) begin
            latch <= 1'b0; clock_out <= 1'b0; state <= LATCH_HIGH;
            counter <= 0; bit_index <= 0;
            for (i = 0; i < 8; i = i + 1) buttons[i] <= 8'h00;
        end else begin
            counter <= counter + 1'b1;
            case (state)
                LATCH_HIGH: begin
                    latch <= 1'b1;
                    if (counter == HALF_PERIOD) begin
                        counter <= 0; state <= LATCH_LOW;
                    end
                end
                LATCH_LOW: begin
                    latch <= 1'b0;
                    // Bit 0 (boton A) ya esta disponible en 'data' apenas baja LATCH
                    for (i = 0; i < 8; i = i + 1) buttons[i][0] <= data[i];
                    bit_index <= 1;
                    if (counter == HALF_PERIOD) begin
                        counter <= 0; state <= CLOCK_HIGH;
                    end
                end
                CLOCK_HIGH: begin
                    clock_out <= 1'b1;
                    if (counter == HALF_PERIOD) begin
                        counter <= 0; state <= CLOCK_LOW;
                    end
                end
                CLOCK_LOW: begin
                    clock_out <= 1'b0;
                    if (counter == HALF_PERIOD) begin
                        counter <= 0;
                        // El flanco de bajada de CLOCK (al ENTRAR a este estado) es lo
                        // que hace que el control saque el siguiente bit en 'data'. Se
                        // captura recien aqui, al SALIR de CLOCK_LOW (ya con margen de
                        // varios ciclos desde ese flanco para que 'data' este estable) --
                        // capturar apenas se entra a CLOCK_LOW leeria el bit viejo,
                        // porque el desplazamiento del control tarda al menos un ciclo
                        // en propagarse.
                        for (i = 0; i < 8; i = i + 1) buttons[i][bit_index] <= data[i];
                        if (bit_index == 3'd7) begin
                            state <= LATCH_HIGH; // vuelve a arrancar el poll (ciclo continuo)
                        end else begin
                            bit_index <= bit_index + 1'b1;
                            state <= CLOCK_HIGH;
                        end
                    end
                end
            endcase
        end
    end

    // ---- Interfaz de registros (lado del bus del SoC), todos de solo lectura ----
    always @(*) begin
        d_out = 32'd0;
        if (cs && rd) begin
            case (addr)
                ADDR_P1: d_out = {24'd0, buttons[0]};
                ADDR_P2: d_out = {24'd0, buttons[1]};
                ADDR_P3: d_out = {24'd0, buttons[2]};
                ADDR_P4: d_out = {24'd0, buttons[3]};
                ADDR_P5: d_out = {24'd0, buttons[4]};
                ADDR_P6: d_out = {24'd0, buttons[5]};
                ADDR_P7: d_out = {24'd0, buttons[6]};
                ADDR_P8: d_out = {24'd0, buttons[7]};
                default: d_out = 32'd0;
            endcase
        end
    end
endmodule
