`timescale 1ns/1ps

// display_driver — modulo top de UNA pantalla: junta vga_timing.v
// (senal de video 640x480@60Hz) + framebuffer.v (memoria de 128 KB de
// esa pantalla), leyendo el color en (pixel_x, pixel_y) para armar
// r,g,b. Se instancia 4 veces en el SoC, una por pantalla, cada una con
// su propio framebuffer -- si el framebuffer de una pantalla se corrompe
// o esta lento, las otras 3 no se ven afectadas.
//
// FB_WIDTH/FB_HEIGHT son la resolucion REAL del juego (mucho menor que
// 640x480, ver README.md -- "problema del tamaño del framebuffer"). Son
// PROVISIONALES: la resolucion final de cada juego sigue siendo un
// punto de coordinacion abierto entre Grupo J, Grupo C y Grupo K (ver
// ../../../docs/decisiones_cerradas.md). Mientras no se decida, este
// modulo dibuja el area FB_WIDTH x FB_HEIGHT sin escalar, pegada a la
// esquina superior izquierda del raster de 640x480; el resto se ve
// negro.

module display_driver #(
    parameter FB_WIDTH  = 256, // PROVISIONAL -- ver nota arriba
    parameter FB_HEIGHT = 200  // PROVISIONAL -- ver nota arriba
) (
    input  wire        clk_pixel, // ~25 MHz, desde PLL
    output wire         hsync, vsync,
    output reg  [3:0]   r, g, b,          // ajustar ancho segun DAC/resistencias reales disponibles
    output wire [9:0]   pixel_x, pixel_y, // coordenadas completas del raster VGA (640x480)

    // Puerto de escritura del framebuffer, expuesto hacia el
    // decodificador del SoC (bus del CPU) -- ver README, "Integracion en el SoC"
    input  wire [14:0]  fb_addr_cpu,
    input  wire [31:0]  fb_data_in,
    input  wire         fb_write_enable,
    input  wire [3:0]   fb_byte_enable,
    output wire [31:0]  fb_data_out
);
    wire video_on;

    vga_timing TIMING (
        .clk_pixel(clk_pixel), .hsync(hsync), .vsync(vsync),
        .video_on(video_on), .pixel_x(pixel_x), .pixel_y(pixel_y)
    );

    // Dentro del area de juego (FB_WIDTH x FB_HEIGHT) vs. resto del
    // raster de 640x480 (se muestra negro, sin escalar ni repetir).
    wire dentro_area = (pixel_x < FB_WIDTH) && (pixel_y < FB_HEIGHT);
    wire [15:0] fb_pixel_addr = pixel_y * FB_WIDTH + pixel_x; // valido solo si dentro_area

    wire [15:0] color;
    framebuffer FB (
        .clk(clk_pixel),
        .addr_cpu(fb_addr_cpu), .data_in(fb_data_in),
        .write_enable(fb_write_enable), .byte_enable(fb_byte_enable),
        .data_out(fb_data_out),
        .addr_pixel(fb_pixel_addr), .pixel_out(color)
    );

    // Formato de color PROVISIONAL: 4-4-4 RGB dentro de los 16 bits del
    // pixel (bits altos sin usar) -- a ajustar segun el DAC real (ver README).
    always @(posedge clk_pixel) begin
        if (video_on && dentro_area) begin
            r <= color[15:12];
            g <= color[11:8];
            b <= color[7:4];
        end else begin
            r <= 4'h0; g <= 4'h0; b <= 4'h0; // fuera del area de juego o en blanking = negro
        end
    end
endmodule
