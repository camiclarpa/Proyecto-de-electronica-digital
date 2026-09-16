# Grupo C — spiram_ctrl.v

Controlador de RAM externa por SPI (posible VRAM extendida).

## Función en el proyecto

La BRAM interna de la FPGA (Grupo A) es pequeña. Si los 4 framebuffers
(uno por pantalla, ver Grupo J) no caben en BRAM interna, esta RAM SPI
externa sirve como memoria adicional — candidata natural para guardar
los 4 framebuffers completos o el estado extendido de los juegos.

## Protocolo real

SPI modo 0 (CPOL=0, CPHA=0) hacia un chip de RAM serial (SPI SRAM/PSRAM,
ej. familia APS6404 o 23LC1024 — **confirmar con el grupo qué chip
específico trae la tarjeta o se va a añadir**). Señales: `CS_n`, `SCLK`,
`MOSI`, `MISO` (o `SIO0-3` si es modo Quad-SPI). Comandos típicos:
`0x02` (WRITE), `0x03` (READ), dirección de 24 bits.

## Interfaz esperada (puertos del módulo)

```verilog
module spiram_ctrl (
    input  wire        clk,
    input  wire [23:0] addr,
    input  wire [31:0] data_in,
    output reg  [31:0] data_out,
    input  wire         req,        // pulso: iniciar transaccion
    input  wire         we,         // 1 = escritura, 0 = lectura
    output reg           busy,       // 1 mientras dura la transaccion SPI
    // pines fisicos hacia el chip externo:
    output wire cs_n, sclk, mosi,
    input  wire miso
);
```

- El CPU debe sondear `busy` antes de asumir que `data_out` es válido
  (una transacción SPI tarda varios ciclos de reloj del sistema, no es
  instantánea como la BRAM).

## Mapa de memoria (PROPUESTO — validar contra el decodificador real `chip_select.v`)

| Dirección | Nombre | Lectura/Escritura | Descripción |
|---|---|---|---|
| `0x00020000` – `0x0002FFFF` | SPIRAM | R/W | Ventana de memoria extendida (posible VRAM de los 4 framebuffers) |
| `0x0002FFFC` | SPIRAM_STATUS | R | bit0 = busy |

## Requisitos desde el software (Grupo K)
- Si se usa como VRAM: el Grupo J necesita saber la dirección base y el
  stride (bytes por fila) de cada uno de los 4 framebuffers dentro de
  este espacio — **definir junto con Grupo J antes de implementar**.
- El acceso NO es instantáneo: el software debe evitar escribir/leer en
  un bucle apretado esperando cada pixel; conviene escribir en bloques.

## Estado
- [ ] Módulo diseñado
- [ ] Módulo simulado (testbench)
- [ ] Módulo probado en hardware real (Colorlight 5A-75E)
- [ ] Mapa de registros/memoria documentado (ver arriba)
