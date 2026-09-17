`timescale 1ns/1ps

// Prueba minima: escribe una palabra completa, luego escribe SOLO el
// byte bajo de otra direccion (byte_enable = 4'b0001) y verifica que
// los otros 3 bytes de esa palabra no se hayan tocado -- esto es
// exactamente lo que necesita el compilador de C cuando genera SB/SH.

module bram_TB;
    reg clk = 0;
    reg [19:0] addr;
    reg [31:0] data_in;
    wire [31:0] data_out;
    reg write_enable;
    reg [3:0] byte_enable;

    bram DUT (
        .clk(clk), .addr(addr), .data_in(data_in), .data_out(data_out),
        .write_enable(write_enable), .byte_enable(byte_enable)
    );

    always #5 clk = ~clk;

    initial begin
        $dumpfile("bram_TB.vcd");
        $dumpvars(0, bram_TB);

        // Escribir palabra completa en addr 0
        addr = 0; data_in = 32'hAABBCCDD; write_enable = 1; byte_enable = 4'b1111;
        @(posedge clk);
        write_enable = 0;
        @(posedge clk);
        if (data_out === 32'hAABBCCDD)
            $display("PASS: escritura de palabra completa OK");
        else
            $display("FAIL: se esperaba 0xAABBCCDD, se obtuvo 0x%h", data_out);

        // Escribir SOLO el byte bajo (simula un SB de C) sobre la misma direccion
        data_in = 32'h000000FF; write_enable = 1; byte_enable = 4'b0001;
        @(posedge clk);
        write_enable = 0;
        @(posedge clk);
        if (data_out === 32'hAABBCCFF)
            $display("PASS: escritura parcial (byte_enable) no toco los otros 3 bytes");
        else
            $display("FAIL: se esperaba 0xAABBCCFF, se obtuvo 0x%h", data_out);

        $finish;
    end
endmodule
