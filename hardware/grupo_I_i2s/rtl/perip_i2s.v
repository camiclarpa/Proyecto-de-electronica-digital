`timescale 1ns/1ps

// perip_i2s — 4 transmisores I2S independientes (uno por pantalla),
// mapeados en el bus de perifericos del SoC.
//
// "addr" es el OFFSET LOCAL dentro de la ventana de este periferico
// (0x470000-0x47FFFF, ver ../../../docs/mapa_memoria.md) -- el
// decodificador del SoC resta la base antes de conectarlo aqui, igual
// que exige la convencion del curso (ver README.md de esta carpeta).
//
// Por que 4 instancias y no 1 sola con mezcla en software: ver la
// seccion "Como se resuelve el audio de las 4 pantallas" del README de
// esta carpeta -- es una respuesta ya cerrada por el equipo, no una
// duda abierta.

module perip_i2s #(
    parameter CLK_FREQ    = 25000000,
    parameter SAMPLE_RATE = 8000,
    parameter BITS        = 16
) (
    input  wire        clk,
    input  wire        rst,
    input  wire [31:0] d_in,
    input  wire        cs,
    input  wire [4:0]  addr,
    input  wire        rd,
    input  wire        wr,
    output reg  [31:0] d_out,

    // Canal 1 -- Pantalla 1
    output wire         bclk1, lrclk1, sdata1,
    // Canal 2 -- Pantalla 2
    output wire         bclk2, lrclk2, sdata2,
    // Canal 3 -- Pantalla 3
    output wire         bclk3, lrclk3, sdata3,
    // Canal 4 -- Pantalla 4
    output wire         bclk4, lrclk4, sdata4
);
    localparam ADDR_AUDIO1 = 5'h00; // 0x00 - AUDIO1_DATA (Pantalla 1)
    localparam ADDR_AUDIO2 = 5'h04; // 0x04 - AUDIO2_DATA (Pantalla 2)
    localparam ADDR_AUDIO3 = 5'h08; // 0x08 - AUDIO3_DATA (Pantalla 3)
    localparam ADDR_AUDIO4 = 5'h0C; // 0x0C - AUDIO4_DATA (Pantalla 4)
    localparam ADDR_STATUS = 5'h10; // 0x10 - AUDIO_STATUS

    // Pulso de escritura por canal: alto SOLO durante el ciclo en que el
    // CPU escribe su registro AUDIOx_DATA -- cada canal solo reacciona a
    // SU propia escritura, nunca a la de otra pantalla (aislamiento).
    wire sample_write1 = cs && wr && (addr == ADDR_AUDIO1);
    wire sample_write2 = cs && wr && (addr == ADDR_AUDIO2);
    wire sample_write3 = cs && wr && (addr == ADDR_AUDIO3);
    wire sample_write4 = cs && wr && (addr == ADDR_AUDIO4);

    wire sample_req1, sample_req2, sample_req3, sample_req4;

    i2s_tx #(.CLK_FREQ(CLK_FREQ), .SAMPLE_RATE(SAMPLE_RATE), .BITS(BITS)) CH1 (
        .clk(clk), .rst(rst), .bclk(bclk1), .lrclk(lrclk1), .sdata(sdata1),
        .sample_in(d_in[BITS-1:0]), .sample_write(sample_write1), .sample_req(sample_req1)
    );
    i2s_tx #(.CLK_FREQ(CLK_FREQ), .SAMPLE_RATE(SAMPLE_RATE), .BITS(BITS)) CH2 (
        .clk(clk), .rst(rst), .bclk(bclk2), .lrclk(lrclk2), .sdata(sdata2),
        .sample_in(d_in[BITS-1:0]), .sample_write(sample_write2), .sample_req(sample_req2)
    );
    i2s_tx #(.CLK_FREQ(CLK_FREQ), .SAMPLE_RATE(SAMPLE_RATE), .BITS(BITS)) CH3 (
        .clk(clk), .rst(rst), .bclk(bclk3), .lrclk(lrclk3), .sdata(sdata3),
        .sample_in(d_in[BITS-1:0]), .sample_write(sample_write3), .sample_req(sample_req3)
    );
    i2s_tx #(.CLK_FREQ(CLK_FREQ), .SAMPLE_RATE(SAMPLE_RATE), .BITS(BITS)) CH4 (
        .clk(clk), .rst(rst), .bclk(bclk4), .lrclk(lrclk4), .sdata(sdata4),
        .sample_in(d_in[BITS-1:0]), .sample_write(sample_write4), .sample_req(sample_req4)
    );

    // ---- Interfaz de registros (lado del bus del SoC) ----
    always @(*) begin
        d_out = 32'd0;
        if (cs && rd && addr == ADDR_STATUS)
            d_out = {28'd0, sample_req4, sample_req3, sample_req2, sample_req1};
    end
endmodule

// i2s_tx — un transmisor I2S individual (BCLK + LRCLK/WS + SDATA, MSB
// primero). Instanciado 4 veces arriba, una por pantalla, sin compartir
// estado entre canales.
module i2s_tx #(
    parameter CLK_FREQ    = 25000000,
    parameter SAMPLE_RATE = 8000,
    parameter BITS        = 16
) (
    input  wire clk, rst,
    output reg  bclk, lrclk, sdata,
    input  wire signed [BITS-1:0] sample_in,
    input  wire                    sample_write, // pulso: nueva muestra lista
    output reg                     sample_req     // pulso: el modulo pide la siguiente muestra
);
    localparam integer BCLK_DIV = CLK_FREQ / (SAMPLE_RATE * BITS * 2 * 2);

    reg [15:0] bclk_count;
    reg [4:0]  bit_index;
    reg signed [BITS-1:0] shift_reg;
    // activo: en reposo (BCLK quieto) hasta que el CPU escribe la primera
    // muestra de ESTE canal -- así un canal al que nadie le ha escrito
    // nunca genera actividad en su bus I2S, que es justamente lo que
    // garantiza el aislamiento entre pantallas (ver README, diagramas/README.md).
    reg activo;

    always @(posedge clk) begin
        if (rst) begin
            bclk <= 1'b0; lrclk <= 1'b0; sdata <= 1'b0;
            bclk_count <= 0; bit_index <= 0; sample_req <= 1'b0; shift_reg <= 0;
            activo <= 1'b0;
        end else begin
            sample_req <= 1'b0;

            if (sample_write) begin
                shift_reg <= sample_in;
                activo    <= 1'b1;
            end else if (activo) begin
                if (bclk_count == BCLK_DIV-1) begin
                    bclk_count <= 0;
                    bclk       <= ~bclk;
                    if (bclk) begin // flanco de bajada de bclk: sacar el siguiente bit
                        sdata     <= shift_reg[BITS-1];
                        shift_reg <= shift_reg << 1;
                        bit_index <= bit_index + 1'b1;
                        if (bit_index == BITS-1) begin
                            lrclk      <= ~lrclk; // cambia de canal (o repite si es mono)
                            sample_req <= 1'b1;   // pide la siguiente muestra
                        end
                    end
                end else bclk_count <= bclk_count + 1'b1;
            end
        end
    end
endmodule
