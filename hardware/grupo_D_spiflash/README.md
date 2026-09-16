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

## Estado
- [ ] Módulo diseñado
- [ ] Módulo simulado (testbench)
- [ ] Módulo probado en hardware real (Colorlight 5A-75E)
- [ ] Mapa de registros/memoria documentado (ver arriba)
