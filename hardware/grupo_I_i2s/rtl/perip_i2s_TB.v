`timescale 1ns/1ps

// Prueba minima: escribe una muestra SOLO en AUDIO1_DATA (canal 1) y
// verifica dos cosas -- (1) que el canal 1 arranca a generar BCLK, y
// (2) que los canales 2-4 permanecen inactivos porque nadie les
// escribio -- esto es justamente lo que garantiza el aislamiento entre
// pantallas que documenta el README (el audio de una pantalla nunca
// depende de las otras 3).

module perip_i2s_TB;
    reg clk = 0;
    reg rst = 1;
    reg [31:0] d_in;
    reg cs, rd, wr;
    reg [4:0] addr;
    wire [31:0] d_out;
    wire bclk1, lrclk1, sdata1;
    wire bclk2, lrclk2, sdata2;
    wire bclk3, lrclk3, sdata3;
    wire bclk4, lrclk4, sdata4;

    perip_i2s #(.CLK_FREQ(1000000), .SAMPLE_RATE(8000), .BITS(16)) DUT (
        .clk(clk), .rst(rst), .d_in(d_in), .cs(cs), .addr(addr), .rd(rd), .wr(wr), .d_out(d_out),
        .bclk1(bclk1), .lrclk1(lrclk1), .sdata1(sdata1),
        .bclk2(bclk2), .lrclk2(lrclk2), .sdata2(sdata2),
        .bclk3(bclk3), .lrclk3(lrclk3), .sdata3(sdata3),
        .bclk4(bclk4), .lrclk4(lrclk4), .sdata4(sdata4)
    );

    always #5 clk = ~clk; // 100 MHz de simulacion

    // Flags "sticky": quedan en 1 en cuanto el bclk correspondiente se
    // vio en alto alguna vez -- mas robusto que comparar un snapshot
    // antes/despues (con BCLK conmutando muy rapido en simulacion, un
    // numero par de flancos podria devolver al mismo valor por casualidad).
    reg vio_bclk1_alto = 0, vio_bclk2_alto = 0, vio_bclk3_alto = 0, vio_bclk4_alto = 0;
    always @(posedge clk) begin
        if (bclk1) vio_bclk1_alto <= 1'b1;
        if (bclk2) vio_bclk2_alto <= 1'b1;
        if (bclk3) vio_bclk3_alto <= 1'b1;
        if (bclk4) vio_bclk4_alto <= 1'b1;
    end

    initial begin
        $dumpfile("perip_i2s_TB.vcd");
        $dumpvars(0, perip_i2s_TB);

        cs = 0; rd = 0; wr = 0; addr = 0; d_in = 0;
        #20 rst = 0;

        // Escribir una muestra en AUDIO1_DATA -> dispara SOLO el canal 1
        @(posedge clk);
        cs = 1; wr = 1; addr = 5'h00; d_in = 32'h00001234;
        @(posedge clk);
        wr = 0; cs = 0;

        // Dejar correr el tiempo suficiente para varios flancos de BCLK del canal 1
        #20000;

        if (vio_bclk1_alto)
            $display("PASS: bclk1 conmuto tras escribir AUDIO1_DATA (canal 1 arranco)");
        else
            $display("FAIL: bclk1 nunca conmuto, el canal 1 no arranco");

        if (!vio_bclk2_alto && !vio_bclk3_alto && !vio_bclk4_alto)
            $display("PASS: canales 2-4 siguen inactivos (aislamiento entre pantallas OK)");
        else
            $display("FAIL: un canal que no debia arrancar se activo");

        // Leer AUDIO_STATUS solo para verificar que la lectura del registro no rompe nada
        cs = 1; rd = 1; addr = 5'h10;
        @(posedge clk);
        $display("INFO: AUDIO_STATUS leido = 0x%h", d_out);

        $finish;
    end
endmodule
