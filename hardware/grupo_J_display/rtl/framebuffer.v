`timescale 1ns/1ps

// framebuffer — memoria de video de UNA pantalla (128 KB, ventana
// oficial confirmada 2026-09-16, ver ../../../docs/mapa_memoria.md).
//
// Igual que bram.v (ver ../../grupo_A_bram/rtl/bram.v), esta NO es un
// periferico de registros de control (no usa cs/rd/wr de un solo
// registro a la vez) -- es memoria real, con DOS puertos independientes
// porque se accede desde dos lados distintos al mismo tiempo:
//   - Puerto CPU: el juego escribe pixel por pixel via SW/SH, por
//     PALABRA de 32 bits con escritura parcial por byte (mismo patron
//     de banco-por-byte que bram.v).
//   - Puerto de video: el generador de timing VGA (vga_timing.v, via
//     display_driver.v) LEE continuamente del framebuffer activo para
//     armar la señal de color, un PIXEL de 16 bits a la vez.
//
// Formato de color: 16 bits/pixel (ver software/grupo_K_juegos/comun/
// framebuffer.h, que ya usa "unsigned short color"). Cada palabra de
// 32 bits del puerto CPU guarda 2 pixeles (el bit bajo de la direccion
// de pixel elige la mitad baja o alta de la palabra).
//
// Se instancia 4 veces, una por pantalla (ver display_driver.v).

module framebuffer #(
    parameter BYTES = 131072 // 128 KB = ventana oficial por pantalla
) (
    input  wire         clk,

    // ---- Puerto CPU: escritura/lectura por PALABRA de 32 bits, con
    // escritura parcial por byte (igual patron que bram.v) ----
    input  wire [14:0]  addr_cpu,     // direccion de PALABRA: 128KB / 4 = 32768 = 2^15 palabras
    input  wire [31:0]  data_in,
    input  wire         write_enable,
    input  wire [3:0]   byte_enable,
    output reg  [31:0]  data_out,

    // ---- Puerto de video: lectura por PIXEL de 16 bits ----
    input  wire [15:0]  addr_pixel,   // 128KB / 2 bytes-por-pixel = 65536 = 2^16 pixeles
    output reg  [15:0]  pixel_out
);
    reg [7:0] mem0 [0:(BYTES/4)-1]; // byte 0 de cada palabra
    reg [7:0] mem1 [0:(BYTES/4)-1]; // byte 1 de cada palabra
    reg [7:0] mem2 [0:(BYTES/4)-1]; // byte 2 de cada palabra
    reg [7:0] mem3 [0:(BYTES/4)-1]; // byte 3 de cada palabra

    // ---- Puerto CPU (escritura parcial por byte, como bram.v) ----
    always @(posedge clk) begin
        if (write_enable) begin
            if (byte_enable[0]) mem0[addr_cpu] <= data_in[7:0];
            if (byte_enable[1]) mem1[addr_cpu] <= data_in[15:8];
            if (byte_enable[2]) mem2[addr_cpu] <= data_in[23:16];
            if (byte_enable[3]) mem3[addr_cpu] <= data_in[31:24];
        end
        data_out <= {mem3[addr_cpu], mem2[addr_cpu], mem1[addr_cpu], mem0[addr_cpu]};
    end

    // ---- Puerto de video (lectura de PIXEL de 16 bits, independiente
    // del puerto CPU -- addr_pixel[0] elige mitad baja/alta de la
    // palabra que contiene ese pixel) ----
    always @(posedge clk) begin
        if (addr_pixel[0])
            pixel_out <= {mem3[addr_pixel[15:1]], mem2[addr_pixel[15:1]]};
        else
            pixel_out <= {mem1[addr_pixel[15:1]], mem0[addr_pixel[15:1]]};
    end
endmodule
