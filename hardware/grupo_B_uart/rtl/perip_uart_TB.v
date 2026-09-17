`timescale 1ns/1ps

// Prueba minima: escribe un byte en UART_DATA, deja que se transmita,
// y lo recibe de vuelta por loopback (tx conectado directo a rx) --
// verifica el camino completo TX + RX sin necesitar hardware real.

module perip_uart_TB;
    reg clk = 0;
    reg rst = 1;
    reg [31:0] d_in;
    reg cs, rd, wr;
    reg [3:0] addr;
    wire [31:0] d_out;
    wire tx;
    wire rx = tx; // loopback

    perip_uart #(.CLK_FREQ(1000000), .BAUD(115200)) DUT (
        .clk(clk), .rst(rst), .d_in(d_in), .cs(cs), .addr(addr),
        .rd(rd), .wr(wr), .d_out(d_out), .tx(tx), .rx(rx)
    );

    always #5 clk = ~clk; // 100 MHz de simulacion

    initial begin
        $dumpfile("perip_uart_TB.vcd");
        $dumpvars(0, perip_uart_TB);

        cs = 0; rd = 0; wr = 0; addr = 0; d_in = 0;
        #20 rst = 0;

        // Escribir 0x41 ('A') en UART_DATA -> dispara la transmision
        @(posedge clk);
        cs = 1; wr = 1; addr = 4'h0; d_in = 32'h00000041;
        @(posedge clk);
        wr = 0; cs = 0;

        // Esperar a que termine TX + RX por loopback (10 bits x DIV ciclos, con margen)
        #200000;

        cs = 1; rd = 1; addr = 4'h0;
        @(posedge clk);
        if (d_out[7:0] === 8'h41)
            $display("PASS: byte recibido por loopback = 0x%h", d_out[7:0]);
        else
            $display("FAIL: se esperaba 0x41, se obtuvo 0x%h", d_out[7:0]);

        $finish;
    end
endmodule
