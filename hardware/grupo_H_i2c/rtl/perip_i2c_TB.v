`timescale 1ns/1ps

// Prueba: modela un esclavo I2C sencillo en la direccion 0x50 (ACK si
// coincide), con un "clock stretch" en el primer flanco de bajada de
// SCL (retiene el bus para probar que el maestro espera de verdad),
// y ejercita una transaccion de ESCRITURA (verifica que el esclavo
// reciba el byte correcto) y una de LECTURA (verifica que el maestro
// reciba el byte que manda el esclavo), ambas con ACK real.

module perip_i2c_TB;
    localparam SLAVE_ADDR = 7'h50;

    reg clk = 0;
    reg rst = 1;
    reg [31:0] d_in;
    reg cs, rd, wr;
    reg [3:0] addr;
    wire [31:0] d_out;
    wire scl, sda;

    // Pull-ups externos (colector abierto real)
    pullup(scl);
    pullup(sda);

    perip_i2c #(.CLK_FREQ(2000000), .I2C_FREQ(100000)) DUT (
        .clk(clk), .rst(rst), .d_in(d_in), .cs(cs), .addr(addr),
        .rd(rd), .wr(wr), .d_out(d_out), .scl(scl), .sda(sda)
    );

    always #5 clk = ~clk; // 100 MHz de simulacion

    // ---------------------------------------------------------------
    // Estirado de reloj: en el PRIMER flanco de bajada de SCL de toda
    // la simulacion, un dispositivo retiene el bus en 0 unos cuantos
    // "cuartos de bit" antes de soltarlo -- el maestro debe esperar a
    // leer SCL=1 de verdad (ver fase PH1 en perip_i2c.v) antes de
    // seguir, en vez de asumir que ya subio.
    reg stretch_pending = 1'b1;
    reg stretch_oe = 1'b0;
    assign scl = stretch_oe ? 1'b0 : 1'bz;
    always @(negedge scl) begin
        if (stretch_pending) begin
            stretch_pending = 1'b0;
            stretch_oe = 1'b1;
            #400; // retiene el bus mucho mas que una fase normal (50ns)
            stretch_oe = 1'b0;
        end
    end

    // ---------------------------------------------------------------
    // Esclavo I2C de prueba en SLAVE_ADDR: ACK si coincide la
    // direccion, captura el byte escrito, y devuelve READ_BYTE ante
    // una lectura.
    localparam [7:0] READ_BYTE = 8'hA7;
    reg [2:0] sstate = 0; // 0=IDLE 1=ADDR 2=ACK_ADDR 3=WDATA 4=ACK_WDATA 5=RDATA 6=WAIT_MACK
    reg [7:0] sshift;
    reg [3:0] sbitcnt;
    reg       s_rw;
    reg       s_addr_match;
    reg [7:0] captured_write_byte;
    reg       s_sda_oe = 1'b0;
    assign sda = s_sda_oe ? 1'b0 : 1'bz;

    always @(negedge sda) if (scl === 1'b1) begin // condicion START
        sstate = 1; sbitcnt = 0; s_sda_oe = 1'b0;
    end
    always @(posedge sda) if (scl === 1'b1) begin // condicion STOP
        sstate = 0; s_sda_oe = 1'b0;
    end

    always @(posedge scl) begin
        case (sstate)
            1: begin sshift <= {sshift[6:0], sda}; sbitcnt <= sbitcnt + 1'b1; end
            3: begin sshift <= {sshift[6:0], sda}; sbitcnt <= sbitcnt + 1'b1; end
            default: ;
        endcase
    end

    always @(negedge scl) begin
        case (sstate)
            1: if (sbitcnt == 4'd8) begin
                   s_addr_match = (sshift[7:1] == SLAVE_ADDR);
                   s_rw = sshift[0];
                   s_sda_oe = s_addr_match ? 1'b1 : 1'b0;
                   sstate = 2;
               end
            2: begin
                   s_sda_oe = 1'b0;
                   if (!s_addr_match) begin
                       sstate = 0;
                   end else if (s_rw) begin
                       sshift = READ_BYTE; sbitcnt = 0; sstate = 5;
                       s_sda_oe = ~sshift[7];
                   end else begin
                       sbitcnt = 0; sstate = 3;
                   end
               end
            3: if (sbitcnt == 4'd8) begin
                   captured_write_byte = sshift;
                   s_sda_oe = 1'b1; sstate = 4;
               end
            4: begin s_sda_oe = 1'b0; sstate = 0; end
            5: begin
                   sbitcnt = sbitcnt + 1'b1;
                   if (sbitcnt == 4'd8) begin
                       s_sda_oe = 1'b0; sstate = 6;
                   end else begin
                       sshift = {sshift[6:0], 1'b0};
                       s_sda_oe = ~sshift[7];
                   end
               end
            6: sstate = 0;
            default: sstate = 0;
        endcase
    end

    // ---------------------------------------------------------------
    integer errores = 0;

    task escribir_reg(input [3:0] a, input [31:0] v);
        begin
            @(posedge clk); cs = 1; wr = 1; addr = a; d_in = v;
            @(posedge clk); wr = 0; cs = 0;
        end
    endtask

    task leer_reg(input [3:0] a, output [31:0] v);
        begin
            @(posedge clk); cs = 1; rd = 1; addr = a;
            @(posedge clk); v = d_out; #1; cs = 0; rd = 0;
        end
    endtask

    reg [31:0] leido;

    initial begin
        $dumpfile("perip_i2c_TB.vcd");
        $dumpvars(0, perip_i2c_TB);

        cs = 0; rd = 0; wr = 0; addr = 0; d_in = 0;
        #20 rst = 0;
        #20;

        // ---- Transaccion de ESCRITURA: manda 0x3C a SLAVE_ADDR ----
        escribir_reg(4'h0, {25'd0, SLAVE_ADDR});      // I2C_ADDR
        escribir_reg(4'h4, 32'h0000003C);              // I2C_DATA
        escribir_reg(4'h8, 32'h00000001);              // I2C_CTRL: start=1, rw=0

        @(negedge DUT.busy);
        #10;
        leer_reg(4'hC, leido); // I2C_STATUS

        if (leido[1] == 1'b0)
            $display("PASS: escritura sin ack_error");
        else begin
            $display("FAIL: escritura reporto ack_error");
            errores = errores + 1;
        end

        if (captured_write_byte === 8'h3C)
            $display("PASS: el esclavo recibio 0x%h (esperado 0x3C)", captured_write_byte);
        else begin
            $display("FAIL: el esclavo recibio 0x%h, se esperaba 0x3C", captured_write_byte);
            errores = errores + 1;
        end

        #200;

        // ---- Transaccion de LECTURA: pide un byte a SLAVE_ADDR ----
        escribir_reg(4'h0, {25'd0, SLAVE_ADDR});      // I2C_ADDR
        escribir_reg(4'h8, 32'h00000003);              // I2C_CTRL: start=1, rw=1

        @(negedge DUT.busy);
        #10;
        leer_reg(4'hC, leido); // I2C_STATUS
        if (leido[1] == 1'b0)
            $display("PASS: lectura sin ack_error");
        else begin
            $display("FAIL: lectura reporto ack_error");
            errores = errores + 1;
        end

        leer_reg(4'h4, leido); // I2C_DATA
        if (leido[7:0] === READ_BYTE)
            $display("PASS: dato leido = 0x%h (esperado 0x%h)", leido[7:0], READ_BYTE);
        else begin
            $display("FAIL: dato leido = 0x%h, se esperaba 0x%h", leido[7:0], READ_BYTE);
            errores = errores + 1;
        end

        if (errores == 0)
            $display("RESULTADO: TODAS LAS PRUEBAS PASARON");
        else
            $display("RESULTADO: %0d PRUEBA(S) FALLARON", errores);

        $finish;
    end

    // Salvavidas: si el maestro se cuelga esperando SCL (bug real de
    // clock stretching), no dejar la simulacion correr para siempre.
    initial begin
        #50000;
        $display("FAIL: TIMEOUT -- el maestro nunca termino (revisar manejo de SCL/clock stretching)");
        $finish;
    end
endmodule
