# Grupo C — `perip_spiram`

Controlador de RAM externa por SPI (memoria adicional para framebuffers
u otros datos que no quepan en la BRAM interna del Grupo A).

> **Direcciones actualizadas 2026-09-16**: se confirmaron contra el
> mapa de memoria oficial del curso (antes eran un supuesto propio sin
> validar). Detalle en
> [`../../docs/decisiones_cerradas.md`](../../docs/decisiones_cerradas.md).

## Función en el proyecto

La BRAM interna de la FPGA (Grupo A) es pequeña. Si los 4 framebuffers
(uno por pantalla, ver Grupo J) no caben en BRAM interna, esta RAM SPI
externa sirve como memoria adicional — candidata natural para guardar
los 4 framebuffers completos o el estado extendido de los juegos.

## Estructura de esta carpeta

```
grupo_C_spiram/
├── README.md               (este archivo)
├── diagramas/README.md     — protocolo SPI, máquina de estados, tabla de registros
├── rtl/
│   ├── Makefile             — `make sim` para correr la prueba
│   ├── perip_spiram.v       — módulo real (FSM SPI modo 0 + registros)
│   └── perip_spiram_TB.v    — testbench (esclavo SPI simulado)
└── firmware/
    ├── spiram.h              — direcciones + macros de registro
    └── spiram.c              — `spiram_read`, `spiram_write`
```

## Protocolo real

SPI modo 0 (CPOL=0, CPHA=0) hacia un chip de RAM serial (SPI SRAM/PSRAM,
ej. familia APS6404 o 23LC1024 — **confirmar con el grupo qué chip
específico trae la tarjeta o se va a añadir**). Señales físicas: `cs_n`,
`sclk`, `mosi`, `miso`. Comandos: `0x02` (WRITE), `0x03` (READ), seguidos
de dirección de 24 bits y 32 bits de dato. Ver el diagrama completo de
la transacción en [`diagramas/README.md`](diagramas/README.md).

A diferencia de `perip_uart` (registro simple, respuesta en 1 ciclo),
esta es una memoria **externa**: cada acceso de datos dispara una
transacción SPI real que tarda varios ciclos de `clk` — el software
debe sondear el bit `busy` antes de asumir que el dato es válido (ver
`SPIRAM_STATUS` abajo).

## Tabla de registros (CSR)

Offsets relativos a la base de este periférico. La base real y la
ventana completa están en
[`../../docs/mapa_memoria.md`](../../docs/mapa_memoria.md) — **oficial,
confirmada contra el repositorio del profesor** (antes era un supuesto
propio sin validar).

| Registro | Offset | R/W | Descripción |
|---|---|---|---|
| `SPIRAM_BASE` (datos) | `0x0000` – `0xFFFB` | R/W | Ventana pass-through hacia la RAM SPI externa; cada acceso dispara una transacción SPI completa |
| `SPIRAM_STATUS` | `0xFFFC` | R | bit0 = `busy` — 1 mientras dura una transacción SPI en curso |

## Integración en el SoC

`perip_spiram` recibe **`addr` como offset local** (ya restada la base
`0x410000`) — el decodificador central del SoC es responsable de:
1. Comparar la dirección del CPU contra la ventana `0x410000–0x41FFFF`.
2. Generar `cs = 1` solo cuando la dirección cae en esa ventana.
3. Conectar `addr = direccion_cpu - 0x410000` al puerto `addr` del
   módulo (mismo patrón que usa `perip_uart` con su propia base).

## Simulación

```bash
cd rtl
make sim
```

Corre el testbench `perip_spiram_TB.v`: el propio testbench actúa como
"esclavo SPI falso" — captura los bits que salen por `mosi` en una
escritura (y verifica que coincidan con el dato escrito) y entrega un
patrón conocido por `miso` en una lectura (y verifica que el módulo lo
capture correctamente en `SPIRAM_DATA`). También verifica que `busy`
vuelva a 0 al terminar cada transacción.

## API en C

Ver [`firmware/spiram.h`](firmware/spiram.h) y
[`firmware/spiram.c`](firmware/spiram.c):

```c
uint32_t spiram_read(uint32_t offset);
void     spiram_write(uint32_t offset, uint32_t value);
```

Ambas funciones esperan primero a que `busy == 0` (transacción previa
terminada) antes de iniciar la propia. `spiram_read` dispara la
transacción con un primer acceso y vuelve a leer después de esperar a
que termine, ya que el dato no está disponible en el mismo ciclo del
acceso (memoria externa, no BRAM).

## Requisitos desde el software (Grupo K)
- Si se usa como VRAM: el Grupo J necesita saber la dirección base y el
  stride (bytes por fila) de cada uno de los 4 framebuffers dentro de
  este espacio — **definir junto con Grupo J antes de implementar**.
- El acceso NO es instantáneo: el software debe evitar escribir/leer en
  un bucle apretado esperando cada pixel; conviene escribir en bloques.

## Errores comunes a evitar
- No respetar `busy`: si el CPU escribe/lee mientras una transacción
  SPI anterior sigue en curso, se corrompen ambas.
- Confundir el modo SPI (CPOL/CPHA) del chip real usado — cada
  fabricante de RAM SPI puede diferir; verificar la hoja de datos del
  chip específico antes de fijar en qué flanco se envía/captura cada
  bit.
- Usar la dirección ABSOLUTA (`0x410000 + offset`) dentro del propio
  módulo `perip_spiram.v` — el módulo solo debe conocer el offset; la
  base la maneja el decodificador central del SoC.

## Estado
- [x] Módulo diseñado
- [x] Testbench escrito (`perip_spiram_TB.v`)
- [ ] Módulo simulado y verificado (correr `make sim`)
- [ ] Módulo probado en hardware real (Colorlight 5A-75E)
- [x] Mapa de registros documentado (offsets arriba, base oficial confirmada)
- [ ] Chip específico de RAM SPI de la tarjeta confirmado (ver "Protocolo real")
