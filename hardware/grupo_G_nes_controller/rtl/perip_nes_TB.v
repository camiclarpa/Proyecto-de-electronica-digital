`timescale 1ns/1ps

// Prueba: simula 2 controles NES conectados por sus lineas DATA (P1 con
// un patron de botones conocido, P2 "desconectado" = todo en 1 por el
// pull-up de la linea DATA sin nada enchufado) y verifica que el modulo
// los lea correctamente a traves del bus (NES_P1, NES_P2).

module perip_nes_TB;
    reg clk = 0;
    reg rst = 1;
    reg [31:0] d_in;
    reg cs, rd, wr;
    reg [4:0] addr;
    wire [31:0] d_out;
    wire latch, clock_out;
    wire [7:0] data;

    // P1: A=1,B=0,Select=1,Start=0,Up=1,Down=1,Left=0,Right=1 -> 0xB5
    localparam [7:0] PATT_P1 = 8'hB5;
    reg [7:0] shreg_p1;
    reg [7:0] shreg_rest [1:7]; // P2..P8: desconectados (pull-up = todo 1)
    integer k;

    assign data[0] = shreg_p1[0];
    genvar g;
    generate
        for (g = 1; g < 8; g = g + 1) begin : rest
            assign data[g] = shreg_rest[g][0];
        end
    endgenerate

    perip_nes #(.HALF_PERIOD(10)) DUT (
        .clk(clk), .rst(rst), .d_in(d_in), .cs(cs), .addr(addr),
        .rd(rd), .wr(wr), .d_out(d_out),
        .latch(latch), .clock_out(clock_out), .data(data)
    );

    always #5 clk = ~clk; // 100 MHz de simulacion

    // Modelo de CD4021: carga paralela cuando LATCH sube, desplaza en
    // cada flanco de bajada de CLOCK (igual que el hardware real).
    always @(posedge latch) begin
        shreg_p1 <= PATT_P1;
        for (k = 1; k < 8; k = k + 1) shreg_rest[k] <= 8'hFF;
    end
    always @(negedge clock_out) begin
        shreg_p1 <= {1'b1, shreg_p1[7:1]};
        for (k = 1; k < 8; k = k + 1) shreg_rest[k] <= {1'b1, shreg_rest[k][7:1]};
    end

    initial begin
        $dumpfile("perip_nes_TB.vcd");
        $dumpvars(0, perip_nes_TB);

        cs = 0; rd = 0; wr = 0; addr = 0; d_in = 0;
        shreg_p1 = 8'hFF;
        for (k = 1; k < 8; k = k + 1) shreg_rest[k] = 8'hFF;
        #20 rst = 0;

        // Esperar un ciclo completo de poll (latch + 7 pulsos de clock, con margen).
        // Con HALF_PERIOD=10 y clk de 10ns: (latch:2 fases + 7*(clock:2 fases)) * 11
        // ciclos de margen * 10ns = ~1760ns minimo; se espera 1900ns por margen.
        #1900;

        cs = 1; rd = 1; addr = 5'h00; // NES_P1
        @(posedge clk);
        #1;
        if (d_out[7:0] === PATT_P1)
            $display("PASS: NES_P1 = 0x%h (esperado 0x%h)", d_out[7:0], PATT_P1);
        else
            $display("FAIL: NES_P1 = 0x%h, se esperaba 0x%h", d_out[7:0], PATT_P1);

        addr = 5'h04; // NES_P2 (desconectado)
        @(posedge clk);
        #1;
        if (d_out[7:0] === 8'hFF)
            $display("PASS: NES_P2 = 0x%h (control desconectado = todo en 1)", d_out[7:0]);
        else
            $display("FAIL: NES_P2 = 0x%h, se esperaba 0xFF (desconectado)", d_out[7:0]);

        cs = 0; rd = 0;
        $finish;
    end
endmodule
