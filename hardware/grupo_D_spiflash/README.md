# Grupo D — `perip_spiflash`

Controlador de memoria Flash SPI (sprites y assets de los 4 juegos).

> **Direcciones actualizadas 2026-09-16**: se confirmaron contra el
> mapa de memoria oficial del curso (antes eran un supuesto propio sin
> validar). Detalle en
> [`../../docs/decisiones_cerradas.md`](../../docs/decisiones_cerradas.md).

## Función en el proyecto

La Colorlight 5A-75E ya trae una flash SPI a bordo (usada normalmente
para guardar el bitstream de configuración de la FPGA). Este módulo la
lee en modo "usuario" después de que la FPGA ya arrancó, para cargar
ahí los **datos de los 4 juegos**: sprites, tablas de niveles, paletas
de color — todo lo que no cambia en tiempo de ejecución.

## Estructura de esta carpeta

```
grupo_D_spiflash/
├── README.md                 (este archivo)
├── diagramas/README.md       — protocolo SPI, máquina de estados, tabla de registros
├── rtl/
│   ├── Makefile                — `make sim` para correr la prueba
│   ├── perip_spiflash.v        — módulo real (FSM SPI modo 0, solo lectura)
│   └── perip_spiflash_TB.v     — testbench (esclavo SPI simulado)
└── firmware/
    ├── spiflash.h                — direcciones + macros de registro
    └── spiflash.c                — `flash_read`, `cargar_sprites`
```

## Protocolo real

SPI modo 0 (CPOL=0, CPHA=0), comandos estándar JEDEC: `0x03` (READ,
hasta ~25 MHz) es el implementado; `0x0B` (FAST READ, con 1 byte
dummy, velocidades mayores) queda documentado como posible mejora
futura. Solo lectura es indispensable para este proyecto (no se
necesita re-programar la flash desde el juego). Ver el diagrama
completo de la transacción en
[`diagramas/README.md`](diagramas/README.md).

Igual que `perip_spiram` (Grupo C), cada acceso de datos dispara una
transacción SPI real que tarda varios ciclos de `clk` — el software
debe sondear el bit `busy` antes de asumir que el dato es válido.

## Tabla de registros (CSR)

Offsets relativos a la base de este periférico. La base real y la
ventana completa están en
[`../../docs/mapa_memoria.md`](../../docs/mapa_memoria.md) — **oficial,
confirmada contra el repositorio del profesor** (antes era un supuesto
propio sin validar).

| Registro | Offset | R/W | Descripción |
|---|---|---|---|
| `FLASH_BASE` (datos) | `0x0000` – `0xFFFB` | R (solo lectura) | Ventana de assets de los 4 juegos (sprites, niveles, paletas); cada acceso dispara una transacción SPI completa |
| `FLASH_STATUS` | `0xFFFC` | R | bit0 = `busy` — 1 mientras dura una transacción SPI en curso |

**Importante**: hay que reservar un área de la flash que NO se solape
con el bitstream de configuración de la FPGA (normalmente los primeros
megabytes). Definir el offset real donde empiezan los assets del juego
una vez se sepa el tamaño del bitstream compilado — el offset `addr`
de este módulo es relativo al INICIO de esa región reservada, no al
inicio físico del chip de flash.

## Integración en el SoC

`perip_spiflash` recibe **`addr` como offset local** (ya restada la
base `0x420000`) — el decodificador central del SoC es responsable de:
1. Comparar la dirección del CPU contra la ventana `0x420000–0x42FFFF`.
2. Generar `cs = 1` solo cuando la dirección cae en esa ventana.
3. Conectar `addr = direccion_cpu - 0x420000` al puerto `addr` del
   módulo (mismo patrón que usa `perip_uart` y `perip_spiram` con sus
   propias bases).

## Simulación

```bash
cd rtl
make sim
```

Corre el testbench `perip_spiflash_TB.v`: el propio testbench actúa
como "esclavo SPI falso" — verifica que el header transmitido por
`mosi` (comando `0x03` + dirección) sea el correcto, entrega un patrón
conocido por `miso` durante la fase de datos y verifica que el módulo
lo capture correctamente en `FLASH_DATA`. También verifica que `busy`
vuelva a 0 al terminar la transacción.

## API en C

Ver [`firmware/spiflash.h`](firmware/spiflash.h) y
[`firmware/spiflash.c`](firmware/spiflash.c):

```c
uint32_t flash_read(uint32_t offset);
void     cargar_sprites(uint32_t offset_flash, uint32_t* destino_ram, int n_palabras);
```

`flash_read` espera primero a que `busy == 0`, dispara la transacción
con un primer acceso y vuelve a leer después de esperar a que termine
(la memoria es externa, no BRAM, así que el dato no está listo en el
mismo ciclo). `cargar_sprites` es la forma recomendada de usarlo: copia
un bloque completo a RAM/BRAM una sola vez al iniciar cada juego.

## Requisitos desde el software (Grupo K)
- Cada uno de los 4 juegos necesita un "layout" fijo de dónde están sus
  assets dentro de esta región (ej. tabla de offsets al inicio de la
  flash, tipo mini sistema de archivos, o direcciones fijas acordadas
  de antemano — más simple para un proyecto de este tamaño).
- Como es de solo lectura y relativamente lenta comparada con BRAM, los
  sprites se deben cargar UNA VEZ a BRAM/SPIRAM al iniciar cada juego
  (con `cargar_sprites`), no leer de flash en cada frame.

## Errores comunes a evitar
- Leer directamente de flash dentro del bucle de dibujo de cada frame
  (es lenta comparada con BRAM) — siempre copiar los sprites a BRAM/RAM
  una sola vez al iniciar el juego (`cargar_sprites`).
- Pisar la región del bitstream de configuración por no confirmar el
  offset real donde empiezan los assets.
- Usar la dirección ABSOLUTA (`0x420000 + offset`) dentro del propio
  módulo `perip_spiflash.v` — el módulo solo debe conocer el offset; la
  base la maneja el decodificador central del SoC.

## Estado
- [x] Módulo diseñado
- [x] Testbench escrito (`perip_spiflash_TB.v`)
- [ ] Módulo simulado y verificado (correr `make sim`)
- [ ] Módulo probado en hardware real (Colorlight 5A-75E)
- [x] Mapa de registros documentado (offsets arriba, base oficial confirmada)
- [ ] Offset real de inicio de assets confirmado (una vez se sepa el tamaño del bitstream)
