`timescale 1ns/1ps

// Prueba: genera un paquete PS/2 de mouse real (3 bytes: status, dx, dy)
// sobre ps2_clk/ps2_data, simulando al mouse como maestro del reloj, y
// verifica que el modulo lo decodifique bien en
// MOUSE_STATUS/MOUSE_DX/MOUSE_DY/MOUSE_VALID.

module perip_ps2mouse_TB;
    reg clk = 0;
    reg rst = 1;
    reg [31:0] d_in = 0;
    reg cs = 0, rd = 0, wr = 0;
    reg [3:0] addr = 0;
    wire [31:0] d_out;

    reg ps2_clk  = 1;
    reg ps2_data = 1;

    perip_ps2mouse DUT (
        .clk(clk), .rst(rst), .d_in(d_in), .cs(cs), .addr(addr),
        .rd(rd), .wr(wr), .d_out(d_out),
        .ps2_clk(ps2_clk), .ps2_data(ps2_data)
    );

    always #5 clk = ~clk; // 100 MHz de simulacion

    // Envia un byte por PS/2: start(0) + 8 datos LSB primero + paridad impar + stop(1)
    task ps2_send_byte(input [7:0] data);
        integer i;
        reg parity;
        begin
            parity = ^data;
            ps2_data = 1'b0; // start
            #200 ps2_clk = 1'b0; #200 ps2_clk = 1'b1; #200;
            for (i = 0; i < 8; i = i + 1) begin
                ps2_data = data[i];
                #200 ps2_clk = 1'b0; #200 ps2_clk = 1'b1; #200;
            end
            ps2_data = ~parity; // paridad impar
            #200 ps2_clk = 1'b0; #200 ps2_clk = 1'b1; #200;
            ps2_data = 1'b1; // stop
            #200 ps2_clk = 1'b0; #200 ps2_clk = 1'b1; #200;
        end
    endtask

    initial begin
        $dumpfile("perip_ps2mouse_TB.vcd");
        $dumpvars(0, perip_ps2mouse_TB);

        #20 rst = 0;
        #100;

        // Paquete de 3 bytes: status=0x19 (left btn + X-sign), dx=0xFB (-5), dy=0x0A (+10)
        ps2_send_byte(8'h19);
        #200;
        ps2_send_byte(8'hFB);
        #200;
        ps2_send_byte(8'h0A);
        #200;

        cs = 1; rd = 1; addr = 4'hC; // MOUSE_VALID
        @(posedge clk);
        if (d_out[0] === 1'b1)
            $display("PASS: MOUSE_VALID indica paquete nuevo disponible");
        else
            $display("FAIL: MOUSE_VALID no indica paquete nuevo");
        cs = 0; rd = 0;

        cs = 1; rd = 1; addr = 4'h0; // MOUSE_STATUS
        @(posedge clk);
        if (d_out[7:0] === 8'h19)
            $display("PASS: MOUSE_STATUS = 0x%h", d_out[7:0]);
        else
            $display("FAIL: se esperaba status 0x19, se obtuvo 0x%h", d_out[7:0]);
        cs = 0; rd = 0;

        cs = 1; rd = 1; addr = 4'h4; // MOUSE_DX
        @(posedge clk);
        if ($signed(d_out) === -5)
            $display("PASS: MOUSE_DX = %0d", $signed(d_out));
        else
            $display("FAIL: se esperaba DX=-5, se obtuvo %0d", $signed(d_out));
        cs = 0; rd = 0;

        cs = 1; rd = 1; addr = 4'h8; // MOUSE_DY
        @(posedge clk);
        if ($signed(d_out) === 10)
            $display("PASS: MOUSE_DY = %0d", $signed(d_out));
        else
            $display("FAIL: se esperaba DY=10, se obtuvo %0d", $signed(d_out));
        cs = 0; rd = 0;

        $finish;
    end
endmodule
