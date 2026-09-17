`timescale 1ns/1ps

// vga_timing — generador de timing VGA 640x480@60Hz estandar industry.
//
// Este es el esqueleto real que ya existia en el README de este grupo
// (decision ya cerrada de usar VGA, no HDMI -- ver README.md) -- se
// mueve a su propio archivo dentro de rtl/ casi sin cambios, como parte
// de la reorganizacion de carpetas del grupo.

module vga_timing (
    input  wire clk_pixel, // 25 MHz real, desde PLL
    output reg  hsync, vsync,
    output reg  video_on,   // 1 cuando esta en la zona visible (no en blanking)
    output reg  [9:0] pixel_x,
    output reg  [9:0] pixel_y
);
    // Horizontal: 640 visibles + 16 front + 96 sync + 48 back = 800
    // Vertical:   480 visibles + 10 front +  2 sync + 33 back = 525
    reg [9:0] h_count = 0;
    reg [9:0] v_count = 0;

    always @(posedge clk_pixel) begin
        if (h_count == 799) begin h_count <= 0; v_count <= (v_count==524) ? 0 : v_count+1; end
        else h_count <= h_count + 1;

        hsync    <= ~(h_count >= 656 && h_count < 752); // activo en bajo
        vsync    <= ~(v_count >= 490 && v_count < 492); // activo en bajo
        video_on <= (h_count < 640) && (v_count < 480);
        pixel_x  <= h_count;
        pixel_y  <= v_count;
    end
endmodule
