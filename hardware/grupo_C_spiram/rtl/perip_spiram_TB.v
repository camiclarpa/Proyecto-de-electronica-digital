`timescale 1ns/1ps

// Prueba del controlador SPI RAM contra un "esclavo falso" armado en
// el propio testbench (no hay modelo completo del chip externo, pero
// se verifica el protocolo bit a bit igual que si lo hubiera):
//
//  1) ESCRITURA: se dispara una escritura y se capturan por MOSI los
//     32 bits de datos que el modulo realmente saca por el pin --
//     deben coincidir con el valor escrito.
//  2) LECTURA: el testbench actua de esclavo y entrega un patron de
//     32 bits conocido por MISO durante la fase de datos -- el dato
//     que el modulo deja en su registro debe coincidir con ese patron.
//
// En ambos casos tambien se verifica que "busy" (bit0 de STATUS)
// vuelve a 0 al terminar la transaccion.

module perip_spiram_TB;
    reg         clk = 0;
    reg         rst = 1;
    reg  [31:0] d_in;
    reg         cs, rd, wr;
    reg  [15:0] addr;
    wire [31:0] d_out;
    wire        cs_n, sclk, mosi;
    reg         miso;

    localparam [15:0] ADDR_STATUS = 16'hFFFC;
    localparam [31:0] WRITE_PATTERN = 32'hDEADBEEF;
    localparam [31:0] READ_PATTERN  = 32'hA5A5F00D;

    perip_spiram DUT (
        .clk(clk), .rst(rst), .d_in(d_in), .cs(cs), .addr(addr),
        .rd(rd), .wr(wr), .d_out(d_out),
        .cs_n(cs_n), .sclk(sclk), .mosi(mosi), .miso(miso)
    );

    always #5 clk = ~clk; // 100 MHz de simulacion

    // ---- "esclavo falso": captura los 32 bits de datos escritos por MOSI ----
    reg [63:0] mosi_capture;
    always @(posedge DUT.sclk) mosi_capture <= {mosi_capture[62:0], mosi};

    // ---- "esclavo falso": entrega READ_PATTERN por MISO durante la fase
    // de datos (negedges 32..63 de sclk; los primeros 32 son el header
    // comando+direccion, que el esclavo ignora) ----
    integer    neg_count;
    reg [31:0] slave_shift;
    always @(negedge cs_n) neg_count = 0;
    always @(negedge DUT.sclk) begin
        if (neg_count == 32) slave_shift = READ_PATTERN; // arranca justo la fase de datos
        if (neg_count >= 32 && neg_count < 64) begin
            miso <= slave_shift[31];
            slave_shift = {slave_shift[30:0], 1'b0};
        end
        neg_count = neg_count + 1;
    end

    task espera_fin_transaccion;
        integer i;
        begin
            for (i = 0; i < 5000; i = i + 1) begin
                @(posedge clk);
                if (!DUT.busy) i = 5000; // sale del ciclo
            end
        end
    endtask

    initial begin
        $dumpfile("perip_spiram_TB.vcd");
        $dumpvars(0, perip_spiram_TB);

        cs = 0; rd = 0; wr = 0; addr = 0; d_in = 0; miso = 1;
        #20 rst = 0;

        // ---- Test 1: ESCRITURA ----
        @(posedge clk);
        cs = 1; wr = 1; addr = 16'h0000; d_in = WRITE_PATTERN;
        @(posedge clk);
        wr = 0; cs = 0;

        espera_fin_transaccion;

        cs = 1; rd = 1; addr = ADDR_STATUS;
        @(posedge clk);
        if (d_out[0] === 1'b0)
            $display("PASS: busy=0 tras completar la escritura");
        else
            $display("FAIL: busy seguia en 1 tras la escritura");
        cs = 0; rd = 0;

        if (mosi_capture[31:0] === WRITE_PATTERN)
            $display("PASS: dato transmitido por MOSI = 0x%h (coincide)", mosi_capture[31:0]);
        else
            $display("FAIL: se esperaba 0x%h por MOSI, se capturo 0x%h", WRITE_PATTERN, mosi_capture[31:0]);

        #100;

        // ---- Test 2: LECTURA ----
        @(posedge clk);
        cs = 1; rd = 1; addr = 16'h0004;
        @(posedge clk);
        rd = 0; cs = 0;

        espera_fin_transaccion;

        cs = 1; rd = 1; addr = 16'h0004;
        @(posedge clk);
        if (d_out === READ_PATTERN)
            $display("PASS: dato leido = 0x%h (coincide con el esclavo simulado)", d_out);
        else
            $display("FAIL: se esperaba 0x%h, se obtuvo 0x%h", READ_PATTERN, d_out);
        cs = 0; rd = 0;

        $finish;
    end
endmodule
