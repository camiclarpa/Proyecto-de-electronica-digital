`timescale 1ns/1ps

// Prueba: genera una trama PS/2 real de 11 bits (start=0, 8 datos LSB
// primero, paridad impar, stop=1) sobre ps2_clk/ps2_data, simulando al
// teclado como maestro del reloj, y verifica que el modulo la decodifique
// bien en KBD_DATA/KBD_STATUS -- incluye el caso de "tecla soltada"
// (prefijo 0xF0).

module perip_ps2kbd_TB;
    reg clk = 0;
    reg rst = 1;
    reg [31:0] d_in = 0;
    reg cs = 0, rd = 0, wr = 0;
    reg [3:0] addr = 0;
    wire [31:0] d_out;

    reg ps2_clk  = 1;
    reg ps2_data = 1;

    perip_ps2kbd DUT (
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
            parity = ^data; // XOR de los 8 bits = paridad PAR de los datos
            // bit de start
            ps2_data = 1'b0;
            #200 ps2_clk = 1'b0; #200 ps2_clk = 1'b1; #200;
            // 8 bits de datos, LSB primero
            for (i = 0; i < 8; i = i + 1) begin
                ps2_data = data[i];
                #200 ps2_clk = 1'b0; #200 ps2_clk = 1'b1; #200;
            end
            // bit de paridad impar (total de 1s en datos+paridad debe ser impar)
            ps2_data = ~parity;
            #200 ps2_clk = 1'b0; #200 ps2_clk = 1'b1; #200;
            // bit de stop
            ps2_data = 1'b1;
            #200 ps2_clk = 1'b0; #200 ps2_clk = 1'b1; #200;
        end
    endtask

    initial begin
        $dumpfile("perip_ps2kbd_TB.vcd");
        $dumpvars(0, perip_ps2kbd_TB);

        #20 rst = 0;
        #100;

        // Enviar scancode 0x1C (tecla 'A' en Scan Code Set 2)
        ps2_send_byte(8'h1C);
        #200;

        cs = 1; rd = 1; addr = 4'h4; // KBD_STATUS
        @(posedge clk);
        if (d_out[0] === 1'b1)
            $display("PASS: KBD_STATUS indica dato nuevo disponible");
        else
            $display("FAIL: KBD_STATUS no indica dato nuevo");
        cs = 0; rd = 0;

        cs = 1; rd = 1; addr = 4'h0; // KBD_DATA
        @(posedge clk);
        if (d_out[7:0] === 8'h1C && d_out[8] === 1'b0)
            $display("PASS: scancode recibido = 0x%h, key_release = %b", d_out[7:0], d_out[8]);
        else
            $display("FAIL: se esperaba scancode 0x1C sin release, se obtuvo d_out=0x%h", d_out);
        cs = 0; rd = 0;

        // Simular tecla soltada: 0xF0 (break code) seguido del scancode
        ps2_send_byte(8'hF0);
        #200;
        ps2_send_byte(8'h1C);
        #200;

        cs = 1; rd = 1; addr = 4'h0; // KBD_DATA
        @(posedge clk);
        if (d_out[7:0] === 8'h1C && d_out[8] === 1'b1)
            $display("PASS: break code detectado, key_release = %b", d_out[8]);
        else
            $display("FAIL: se esperaba key_release=1, se obtuvo d_out=0x%h", d_out);
        cs = 0; rd = 0;

        $finish;
    end
endmodule
