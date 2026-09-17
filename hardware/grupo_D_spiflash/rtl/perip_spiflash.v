`timescale 1ns/1ps

// perip_spiflash -- controlador de la flash SPI de la tarjeta (modo 0,
// CPOL=0 CPHA=0), en modo "usuario" (post-configuracion de la FPGA),
// mapeado en el bus de perifericos del SoC.
//
// "addr" es el OFFSET LOCAL dentro de la ventana de este periferico
// (0x420000-0x42FFFF, ver ../../../docs/mapa_memoria.md) -- el
// decodificador del SoC resta la base antes de conectarlo aqui, igual
// que exige la convencion del curso (ver README.md de esta carpeta).
//
// Es SOLO LECTURA (assets de los juegos: sprites, niveles, paletas) --
// no hay ruta de escritura. Comando JEDEC READ estandar (0x03), igual
// que perip_spiram pero sin la fase de escritura. Cada lectura dispara
// una transaccion SPI real que tarda varios ciclos de "clk" -- el
// software debe sondear el bit "busy" de FLASH_STATUS.

module perip_spiflash (
    input  wire        clk,
    input  wire         rst,
    input  wire [31:0] d_in,   // sin uso: el periferico es solo lectura
    input  wire        cs,
    input  wire [15:0] addr,   // offset dentro de la ventana de 64KB (0x0000-0xFFFF)
    input  wire        rd,
    input  wire        wr,     // sin uso: el periferico es solo lectura
    output reg  [31:0] d_out,
    // pines fisicos hacia la flash SPI de la tarjeta
    output reg          cs_n,
    output reg          sclk,
    output reg          mosi,
    input  wire          miso
);
    localparam [15:0] ADDR_STATUS = 16'hFFFC; // ultimo word de la ventana de 64KB

    localparam [7:0] CMD_READ = 8'h03; // JEDEC READ (hasta ~25 MHz)

    localparam [1:0] IDLE      = 2'd0,
                      XFER_HDR  = 2'd1, // 32 bits: comando(8) + direccion externa(24)
                      XFER_DATA = 2'd2, // 32 bits leidos por miso
                      DONE      = 2'd3;

    reg [1:0]  state;
    reg [6:0]  bit_count;   // hasta 32
    reg [31:0] shift_out;
    reg [31:0] shift_in;
    reg        busy;
    reg [31:0] data_reg;    // ultimo dato leido, valido cuando busy vuelve a 0

    // direccion externa de 24 bits: la ventana de 64KB se mapea 1:1,
    // byte a byte, sobre la region de assets reservada en la flash
    // (offset dentro de esa region -- ver README, "no solaparse con
    // el bitstream de configuracion de la FPGA").
    wire [23:0] ext_addr = {8'h00, addr};

    always @(posedge clk) begin
        if (rst) begin
            state     <= IDLE;
            cs_n      <= 1'b1;
            sclk      <= 1'b0;
            mosi      <= 1'b0;
            busy      <= 1'b0;
            bit_count <= 7'd0;
        end else begin
            case (state)
                IDLE: begin
                    cs_n <= 1'b1;
                    if (cs && rd && addr != ADDR_STATUS && !busy) begin
                        shift_out <= {CMD_READ, ext_addr};
                        bit_count <= 7'd0;
                        cs_n      <= 1'b0;
                        busy      <= 1'b1;
                        // sclk arranca en 1 (no en 0) para que el primer
                        // ciclo dentro de XFER_HDR sea un flanco de bajada
                        // real (saca el primer bit) en vez de muestrear el
                        // valor viejo de mosi.
                        sclk      <= 1'b1;
                        state     <= XFER_HDR;
                    end
                end

                XFER_HDR: begin
                    sclk <= ~sclk;
                    if (sclk) begin // flanco de bajada: el maestro cambia mosi
                        mosi      <= shift_out[31];
                        shift_out <= {shift_out[30:0], 1'b0};
                    end else begin // flanco de subida: se cuenta el bit ya muestreado
                        bit_count <= bit_count + 1'b1;
                        if (bit_count == 7'd31) begin
                            bit_count <= 7'd0;
                            state     <= XFER_DATA;
                        end
                    end
                end

                XFER_DATA: begin
                    sclk <= ~sclk;
                    if (!sclk) begin // flanco de subida: se muestrea miso
                        shift_in  <= {shift_in[30:0], miso};
                        bit_count <= bit_count + 1'b1;
                        if (bit_count == 7'd31) state <= DONE;
                    end
                end

                DONE: begin
                    cs_n     <= 1'b1;
                    busy     <= 1'b0;
                    data_reg <= shift_in;
                    state    <= IDLE;
                end

                default: state <= IDLE;
            endcase
        end
    end

    // ---- Interfaz de registros (lado del bus del SoC) ----
    always @(*) begin
        d_out = 32'd0;
        if (cs && rd) begin
            if (addr == ADDR_STATUS)
                d_out = {31'd0, busy};
            else
                d_out = data_reg; // ultimo dato capturado (valido cuando busy==0)
        end
    end
endmodule
