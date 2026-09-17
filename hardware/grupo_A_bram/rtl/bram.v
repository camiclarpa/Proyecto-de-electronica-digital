`timescale 1ns/1ps

// bram — memoria de trabajo del CPU (codigo + datos).
//
// A diferencia de los demas modulos de hardware/, esta NO es un
// periferico con registros de control (no necesita cs/addr-offset,
// rd/wr de un solo bit) -- es memoria de programa normal, accedida por
// el CPU con LW/SW/LB/SB directo, igual que cualquier arreglo en C.
// Por eso no se llama "perip_bram" ni sigue el patron CSR del resto.

module bram (
    input  wire        clk,
    input  wire [19:0] addr,        // direccion de PALABRA: ventana de 4MB / 4 bytes = 2^20 palabras (ver docs/mapa_memoria.md: 0x000000-0x3FFFFF)
    input  wire [31:0] data_in,
    output reg  [31:0] data_out,
    input  wire        write_enable,
    input  wire [3:0]  byte_enable  // escritura parcial (SB/SH del RISC-V)
);
    reg [7:0] mem0 [0:1048575];
    reg [7:0] mem1 [0:1048575];
    reg [7:0] mem2 [0:1048575];
    reg [7:0] mem3 [0:1048575];

    always @(posedge clk) begin
        if (write_enable) begin
            if (byte_enable[0]) mem0[addr] <= data_in[7:0];
            if (byte_enable[1]) mem1[addr] <= data_in[15:8];
            if (byte_enable[2]) mem2[addr] <= data_in[23:16];
            if (byte_enable[3]) mem3[addr] <= data_in[31:24];
        end
        data_out <= {mem3[addr], mem2[addr], mem1[addr], mem0[addr]};
    end
endmodule
