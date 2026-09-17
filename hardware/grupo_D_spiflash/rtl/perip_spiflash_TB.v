`timescale 1ns/1ps

// Prueba del controlador SPI Flash contra un "esclavo falso" armado en
// el propio testbench: entrega un patron de 32 bits conocido por MISO
// durante la fase de datos y verifica que el modulo lo capture
// correctamente. Tambien verifica que el header (comando 0x03 +
// direccion) salga correcto por MOSI, y que "busy" vuelva a 0 al
// terminar.

module perip_spiflash_TB;
    reg         clk = 0;
    reg         rst = 1;
    reg  [31:0] d_in;
    reg         cs, rd, wr;
    reg  [15:0] addr;
    wire [31:0] d_out;
    wire        cs_n, sclk, mosi;
    reg         miso;

    localparam [15:0] ADDR_STATUS = 16'hFFFC;
    localparam [15:0] TEST_OFFSET = 16'h0100;
    localparam [31:0] READ_PATTERN = 32'hC0FFEE01;

    perip_spiflash DUT (
        .clk(clk), .rst(rst), .d_in(d_in), .cs(cs), .addr(addr),
        .rd(rd), .wr(wr), .d_out(d_out),
        .cs_n(cs_n), .sclk(sclk), .mosi(mosi), .miso(miso)
    );

    always #5 clk = ~clk; // 100 MHz de simulacion

    // ---- "esclavo falso": captura los 64 bits transferidos por MOSI.
    // Los primeros 32 (header: comando+direccion) quedan en la mitad
    // alta del registro; la mitad baja (fase de datos) no se usa aqui,
    // ya que en lectura el dato viaja por MISO, no por MOSI. ----
    reg [63:0] mosi_capture;
    always @(posedge DUT.sclk) mosi_capture <= {mosi_capture[62:0], mosi};

    // ---- "esclavo falso": entrega READ_PATTERN por MISO durante la fase
    // de datos (negedges 32..63 de sclk; los primeros 32 son el header) ----
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
        $dumpfile("perip_spiflash_TB.vcd");
        $dumpvars(0, perip_spiflash_TB);

        cs = 0; rd = 0; wr = 0; addr = 0; d_in = 0; miso = 1;
        #20 rst = 0;

        // ---- Test 1: LECTURA ----
        @(posedge clk);
        cs = 1; rd = 1; addr = TEST_OFFSET;
        @(posedge clk);
        rd = 0; cs = 0;

        espera_fin_transaccion;

        cs = 1; rd = 1; addr = ADDR_STATUS;
        @(posedge clk);
        if (d_out[0] === 1'b0)
            $display("PASS: busy=0 tras completar la lectura");
        else
            $display("FAIL: busy seguia en 1 tras la lectura");
        cs = 0; rd = 0;

        if (mosi_capture[63:32] === {8'h03, 8'h00, TEST_OFFSET})
            $display("PASS: header transmitido (cmd 0x03 + direccion) = 0x%h (coincide)", mosi_capture[63:32]);
        else
            $display("FAIL: se esperaba header 0x%h, se capturo 0x%h", {8'h03, 8'h00, TEST_OFFSET}, mosi_capture[63:32]);

        cs = 1; rd = 1; addr = TEST_OFFSET;
        @(posedge clk);
        if (d_out === READ_PATTERN)
            $display("PASS: dato leido = 0x%h (coincide con el esclavo simulado)", d_out);
        else
            $display("FAIL: se esperaba 0x%h, se obtuvo 0x%h", READ_PATTERN, d_out);
        cs = 0; rd = 0;

        $finish;
    end
endmodule
