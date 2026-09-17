`timescale 1ns/1ps

// Testbench BASICO de display_driver (a diferencia de perip_uart_TB.v /
// perip_i2s_TB.v, aqui no se persigue el pixel exacto dentro del
// escaneo VGA ciclo a ciclo -- eso depende de la resolucion final del
// juego, todavia PROVISIONAL, ver README). Se verifican dos cosas
// independientes:
//   1. El puerto CPU del framebuffer (dentro de display_driver) escribe
//      y relee correctamente una palabra -- confirma que el bus llega
//      bien hasta la memoria de 128 KB.
//   2. El generador de timing VGA esta vivo: hsync/vsync cambian de
//      valor durante la simulacion (confirma que vga_timing.v corre).

module display_driver_TB;
    reg clk_pixel = 0;
    reg [14:0] fb_addr_cpu;
    reg [31:0] fb_data_in;
    reg        fb_write_enable;
    reg [3:0]  fb_byte_enable;
    wire [31:0] fb_data_out;
    wire hsync, vsync;
    wire [9:0] pixel_x, pixel_y;
    wire [3:0] r, g, b;

    integer i;

    // Flag "sticky": queda en 1 en cuanto hsync se vio en bajo alguna
    // vez -- mas robusto que comparar un snapshot antes/despues (si la
    // ventana de observacion abarca un numero par de flancos, hsync
    // puede volver al mismo valor de antes por casualidad).
    reg vio_hsync_bajo = 0;
    always @(posedge clk_pixel) if (!hsync) vio_hsync_bajo <= 1'b1;

    display_driver #(.FB_WIDTH(256), .FB_HEIGHT(200)) DUT (
        .clk_pixel(clk_pixel), .hsync(hsync), .vsync(vsync),
        .r(r), .g(g), .b(b), .pixel_x(pixel_x), .pixel_y(pixel_y),
        .fb_addr_cpu(fb_addr_cpu), .fb_data_in(fb_data_in),
        .fb_write_enable(fb_write_enable), .fb_byte_enable(fb_byte_enable),
        .fb_data_out(fb_data_out)
    );

    always #20 clk_pixel = ~clk_pixel; // ~25 MHz de simulacion

    initial begin
        $dumpfile("display_driver_TB.vcd");
        $dumpvars(0, display_driver_TB);

        fb_addr_cpu = 0; fb_data_in = 0; fb_write_enable = 0; fb_byte_enable = 0;

        // ---- Prueba 1: puerto CPU del framebuffer (escritura + lectura) ----
        @(posedge clk_pixel);
        fb_addr_cpu = 15'h0100; fb_data_in = 32'hAABBCCDD; fb_write_enable = 1; fb_byte_enable = 4'b1111;
        @(posedge clk_pixel);
        fb_write_enable = 0;
        @(posedge clk_pixel);
        if (fb_data_out === 32'hAABBCCDD)
            $display("PASS: puerto CPU del framebuffer escribe/relee bien (0x%h)", fb_data_out);
        else
            $display("FAIL: se esperaba 0xAABBCCDD, se obtuvo 0x%h", fb_data_out);

        // ---- Prueba 2: el generador de timing VGA esta vivo ----
        for (i = 0; i < 900; i = i + 1) @(posedge clk_pixel); // > 1 linea horizontal completa (800 ciclos)

        if (vio_hsync_bajo)
            $display("PASS: hsync bajo durante la simulacion (vga_timing corriendo, pulso de sync generado)");
        else
            $display("FAIL: hsync nunca bajo, vga_timing no genero el pulso de sync esperado");

        $finish;
    end
endmodule
