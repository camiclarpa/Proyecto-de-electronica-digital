# Grupo D — spi_flash_ctrl.v

Controlador de memoria Flash SPI (sprites y assets de los juegos).

## Función en el proyecto

La Colorlight 5A-75E ya trae una flash SPI a bordo (usada normalmente
para guardar el bitstream de configuración de la FPGA). Este módulo la
lee en modo "usuario" después de que la FPGA ya arrancó, para cargar
ahí los **datos de los 4 juegos**: sprites, tablas de niveles, paletas
de color — todo lo que no cambia en tiempo de ejecución.

## Protocolo real

SPI modo 0, comandos estándar JEDEC: `0x03` (READ, hasta ~25 MHz),
`0x0B` (FAST READ, con 1 byte dummy, velocidades mayores), dirección de
24 bits. Solo lectura es indispensable para este proyecto (no se
necesita re-programar la flash desde el juego).

## Interfaz esperada (puertos del módulo)

```verilog
module spi_flash_ctrl (
    input  wire        clk,
    input  wire [23:0] addr,
    output reg  [31:0] data_out,
    input  wire         req,
    output reg           busy,
    output wire cs_n, sclk, mosi,
    input  wire miso
);
```

## Mapa de memoria (PROPUESTO — validar contra el decodificador real `chip_select.v`)

| Dirección | Nombre | Lectura/Escritura | Descripción |
|---|---|---|---|
| `0x00030000` – `0x0003FFFF` | SPIFLASH | R (solo lectura) | Assets de los 4 juegos (sprites, niveles, paletas) |
| `0x0003FFFC` | SPIFLASH_STATUS | R | bit0 = busy |

**Importante**: hay que reservar un área de la flash que NO se solape
con el bitstream de configuración de la FPGA (normalmente los primeros
megabytes). Definir el offset real donde empiezan los assets del juego
una vez se sepa el tamaño del bitstream compilado.

## Requisitos desde el software (Grupo K)
- Cada uno de los 4 juegos necesita un "layout" fijo de dónde están sus
  assets dentro de esta región (ej. tabla de offsets al inicio de la
  flash, tipo mini sistema de archivos, o direcciones fijas acordadas
  de antemano — más simple para un proyecto de este tamaño).
- Como es de solo lectura y relativamente lenta comparada con BRAM, los
  sprites se deben cargar UNA VEZ a BRAM/SPIRAM al iniciar cada juego,
  no leer de flash en cada frame.

## Esqueleto de implementación (mismo patrón que Grupo C, solo lectura)

```verilog
module spi_flash_ctrl (
    input  wire        clk, rst,
    input  wire [23:0] addr,
    output reg  [31:0] data_out,
    input  wire        req,
    output reg         busy,
    output reg         cs_n, sclk, mosi,
    input  wire        miso
);
    // Igual estructura que spiram_ctrl.v pero SIEMPRE con comando
    // fijo 0x03 (READ) — nunca 0x02 (WRITE), esta memoria es solo
    // lectura desde el punto de vista del juego.
    localparam IDLE=0, XFER=1, DONE=2;
    reg [1:0] state = IDLE;
    reg [5:0] bit_count;
    reg [31:0] shift_out;
    reg [31:0] shift_in;

    always @(posedge clk) begin
        if (rst) begin state <= IDLE; cs_n <= 1; busy <= 0; end
        else case (state)
            IDLE: if (req) begin
                cs_n <= 0; busy <= 1;
                shift_out <= {8'h03, addr};
                bit_count <= 0; state <= XFER;
            end
            XFER: begin
                sclk <= ~sclk;
                if (sclk) begin
                    mosi <= shift_out[31]; shift_out <= {shift_out[30:0], 1'b0};
                end else begin
                    shift_in <= {shift_in[30:0], miso};
                    bit_count <= bit_count + 1;
                    if (bit_count == 63) state <= DONE; // 32 cmd+addr + 32 datos
                end
            end
            DONE: begin cs_n <= 1; busy <= 0; data_out <= shift_in; state <= IDLE; end
        endcase
    end
endmodule
```

## API en C para el Grupo K

```c
// spiflash.h
#define FLASH_BASE   0x00030000
#define FLASH_STATUS (*(volatile unsigned int*)0x0003FFFC)

unsigned int flash_read(unsigned int offset) {
    while (FLASH_STATUS & 0x1) {}
    return *(volatile unsigned int*)(FLASH_BASE + offset);
}

// Ejemplo de carga de sprites al iniciar un juego:
void cargar_sprites(unsigned int offset_flash, unsigned int* destino_ram, int n_palabras) {
    for (int i = 0; i < n_palabras; i++)
        destino_ram[i] = flash_read(offset_flash + i*4);
}
```

## Errores comunes a evitar
- Leer directamente de flash dentro del bucle de dibujo de cada frame
  (es lenta comparada con BRAM) — siempre copiar los sprites a BRAM/RAM
  una sola vez al iniciar el juego.
- Pisar la región del bitstream de configuración por no confirmar el
  offset real donde empiezan los assets.

## Estado
- [ ] Módulo diseñado
- [ ] Módulo simulado (testbench)
- [ ] Módulo probado en hardware real (Colorlight 5A-75E)
- [ ] Mapa de registros/memoria documentado (ver arriba)
