# Grupo J — `display_driver`

Controlador de las 4 salidas de video independientes (una por pantalla).

> **Direcciones actualizadas 2026-09-16**: se confirmaron contra el
> mapa de memoria oficial del curso (antes eran un supuesto propio sin
> validar) y la ventana por pantalla subió de 16 KB a **128 KB**.
> Detalle en
> [`../../docs/decisiones_cerradas.md`](../../docs/decisiones_cerradas.md).

## Función en el proyecto

Es el módulo que convierte lo que hay en el framebuffer de cada juego
en una señal de video real que la pantalla pueda mostrar. Es, junto con
el Grupo G (controles), el módulo más crítico para que el proyecto
"se vea" funcionando.

**✅ DECISIÓN CERRADA (2026-09-16): el FPGA genera VGA, no HDMI.**

Se evaluaron las dos opciones reales para la salida de video de las 4
pantallas:

| Opción | Qué requiere del FPGA | Riesgo real |
|---|---|---|
| **VGA (analógica)** ✅ ELEGIDA | Un contador de timing (`vga_timing`, ver [`rtl/vga_timing.v`](rtl/vga_timing.v)) + un DAC resistivo simple (2-4 resistencias por canal de color) en los pines de salida | Bajo — es el estándar que usan casi todos los cursos universitarios de "Pong/Tetris en FPGA", no necesita IP especial |
| **HDMI (digital, TMDS)** ❌ descartada | 4 transmisores TMDS reales (serializar cada canal a ~250 MHz, 10× el reloj de píxel) — el Colorlight 5A-75E no trae pines diferenciales pensados para esto, y el flujo 100% open-source (Yosys+Nextpnr+Trellis) tiene soporte mucho menos probado para SERDES de alta velocidad que las herramientas propietarias de Lattice | Alto — 4 instancias simultáneas de esto es un proyecto de I+D en sí mismo, no algo razonable en el tiempo del curso |

**Por qué se cierra en VGA:**
1. El código de timing (`vga_timing`) y el mapa de memoria de
   framebuffers ya están escritos asumiendo VGA — cambiar a HDMI
   implicaría rehacer esta parte desde cero.
2. Generar 4 salidas HDMI reales requiere 4 serializadores TMDS de alta
   velocidad — un riesgo de proyecto innecesario para un curso, y sin
   garantía de que el toolchain open-source del curso lo soporte de
   forma confiable a tiempo.
3. **El problema de que la pantalla comprada (ELECROW, ver
   [`mecanica/gabinete/cotizacion_pantalla.md`](../../mecanica/gabinete/cotizacion_pantalla.md))
   solo tenga entrada HDMI se resuelve por fuera del FPGA**: con un
   convertidor activo VGA→HDMI (dispositivo real y barato, ver esa
   cotización), en vez de complicar el diseño de hardware del Grupo J.

Si en el futuro se cambia a pantallas TFT pequeñas por SPI/paralelo
(ej. tipo ILI9341), el protocolo cambiaría por completo — pero esa no
es la ruta elegida.

## Por qué este módulo NO sigue el patrón CSR simple

A diferencia de los demás periféricos de `hardware/` (UART, I2S, I2C,
etc.), este grupo mezcla **dos cosas distintas**:
1. Un generador de timing (`vga_timing`) que sí es puramente lógica de
   control, sin registros del CPU.
2. **4 framebuffers**, cada uno una región de **memoria** de 128 KB (el
   CPU escribe pixel por pixel ahí, como un arreglo) — no un par de
   registros de control como `blink` o `UART`.

Por eso `framebuffer.v` es análogo al caso de la BRAM (ver
[`../grupo_A_bram/README.md`](../grupo_A_bram/README.md#por-qué-no-se-llama-perip_bram-ni-sigue-el-patrón-csr)
y [`../grupo_A_bram/rtl/bram.v`](../grupo_A_bram/rtl/bram.v)): memoria
real, direccionable con suficientes bits (128 KB = 2^17 bytes), sin
protocolo `cs`/cola de un solo registro. El nombre de la carpeta en el
mapa de memoria es `perip_display` solo para efectos de la tabla
consolidada — el módulo RTL en sí no se llama `perip_display.v` porque
no es un CSR (ver nota 4 en
[`../../docs/mapa_memoria.md`](../../docs/mapa_memoria.md)).

## Estructura de esta carpeta

```
grupo_J_display/
├── README.md                 (este archivo)
├── diagramas/README.md       — timing VGA (front porch/sync/back porch), diagrama de bloques
├── rtl/
│   ├── Makefile
│   ├── vga_timing.v            — generador de timing VGA (mismo esqueleto real de siempre)
│   ├── framebuffer.v            — memoria de framebuffer (128 KB), parametrizable, instanciada 4×
│   ├── display_driver.v         — top de una pantalla: junta vga_timing + framebuffer
│   └── display_driver_TB.v      — testbench básico (puerto CPU + timing vivo)
└── firmware/
    ├── display.h                — FB1_BASE..FB4_BASE (referencia a framebuffer.h del Grupo K)
    └── display.c                 — placeholder (la lógica de dibujo vive en el Grupo K)
```

## Protocolo real (VGA, 640×480 @ 60 Hz — timing estándar industry)

| Parámetro | Horizontal | Vertical |
|---|---|---|
| Píxeles visibles | 640 | 480 |
| Front porch | 16 | 10 |
| Sync pulse | 96 | 2 |
| Back porch | 48 | 33 |
| Total | 800 | 525 |

Reloj de píxel: **25.175 MHz** (aprox. 25 MHz, generado con un PLL a
partir del reloj de la placa — el mismo tipo de PLL que ya usa la
carpeta `pll/` del ejemplo `from-blinker-to-riscv-bruno-levy` del
repositorio del curso). `HSYNC` y `VSYNC` activos en bajo en esta
resolución estándar; 3 salidas de color (R, G, B). Con **4 pantallas**
se necesitan 4 instancias de `vga_timing` corriendo en paralelo (ver
diagrama de bloques en
[`diagramas/README.md`](diagramas/README.md)). Detalle completo del
timing (front porch/sync/back porch) también en esa carpeta.

## Tabla de ventanas de framebuffer

| Nombre | Base | Ventana | Tamaño | R/W |
|---|---|---|---|---|
| `FB1_BASE` | `0x00480000` | `0x480000`–`0x49FFFF` | 128 KB | R/W |
| `FB2_BASE` | `0x004A0000` | `0x4A0000`–`0x4BFFFF` | 128 KB | R/W |
| `FB3_BASE` | `0x004C0000` | `0x4C0000`–`0x4DFFFF` | 128 KB | R/W |
| `FB4_BASE` | `0x004E0000` | `0x4E0000`–`0x4FFFFF` | 128 KB | R/W |

Base del grupo completo: `0x00480000`, ventana total `0x480000`–`0x4FFFFF` (512 KB).

## Nota real importante: el problema del tamaño del framebuffer (SIGUE VIGENTE)

Un framebuffer de 640×480 a color completo (ej. 12 bits/píxel) pesa
**~460 KB** — con la ventana oficial ahora subida a **128 KB por
pantalla** (antes 16 KB) hay mucho más margen que antes, pero **sigue
sin caber un framebuffer completo a resolución máxima** (128 KB < 460
KB). Opciones reales, sin cambiar:
(a) usar una resolución mucho más baja tipo los juegos retro reales
(ej. 160×120 o 256×200, del orden de 20-50 KB según bits/píxel, mucho
más manejable), o
(b) guardar el framebuffer en la SPIRAM externa del Grupo C en vez de
usar solo esta memoria interna.
**Definir esto sigue siendo uno de los primeros puntos de coordinación
entre Grupo J, Grupo C y Grupo K** — ver el registro completo en
[`../../docs/decisiones_cerradas.md`](../../docs/decisiones_cerradas.md#punto-de-coordinación-activo-no-es-una-decisión-es-un-riesgo-técnico-documentado).
Mientras esto no se cierre, `display_driver.v` usa `FB_WIDTH`/
`FB_HEIGHT` **provisionales** (256×200 por defecto, ver el módulo) que
deben ajustarse cuando el equipo decida la resolución final de cada
juego.

## Integración en el SoC

Cada `display_driver` (uno por pantalla) recibe **`fb_addr_cpu` como
offset local de PALABRA** (ya restada la base de esa pantalla) — el
decodificador central del SoC es responsable de:
1. Comparar la dirección del CPU contra la ventana de 128 KB de la
   pantalla correspondiente (`0x480000–0x49FFFF` para FB1, y así con
   cada una).
2. Generar `fb_write_enable = 1` solo cuando la dirección cae en esa
   ventana Y la operación es una escritura.
3. Conectar `fb_addr_cpu = (direccion_cpu - FBn_BASE) >> 2` (offset de
   palabra de 32 bits) al puerto correspondiente del `display_driver`
   de esa pantalla — mismo patrón de resta de base que usan los demás
   grupos (ver
   [`../grupo_B_uart/README.md`](../grupo_B_uart/README.md#integración-en-el-soc)),
   pero aquí sobre una ventana de memoria completa, no un solo registro.
4. El lado de video (`vga_timing` + lectura de `framebuffer`) **no
   depende del CPU en absoluto** — corre siempre, a su propio reloj de
   píxel, leyendo lo último que el CPU haya escrito.

## Simulación

```bash
cd rtl
make sim
```

Corre `display_driver_TB.v`: (1) escribe y relee una palabra por el
puerto CPU del framebuffer para confirmar que el bus llega bien hasta
la memoria de 128 KB, y (2) confirma que `vga_timing` está generando
`hsync`/`vsync` (timing vivo). No persigue un píxel exacto dentro del
escaneo — eso depende de la resolución final del juego, todavía
provisional (ver nota de arriba).

## API en C para el Grupo K

El CPU **no controla el timing** (eso lo hace el hardware solo), solo
escribe en el framebuffer correspondiente a su pantalla. Las
direcciones están en [`firmware/display.h`](firmware/display.h):

```c
#define FB1_BASE 0x00480000u
#define FB2_BASE 0x004A0000u
#define FB3_BASE 0x004C0000u
#define FB4_BASE 0x004E0000u
```

Las funciones de dibujo reales (`limpiar_pantalla`, `poner_pixel`,
`dibujar_sprite`, `dibujar_texto`) **no se duplican aquí** — ya están
declaradas y son compartidas por los 4 juegos en
[`../../software/grupo_K_juegos/comun/framebuffer.h`](../../software/grupo_K_juegos/comun/framebuffer.h),
que recibe `fb_base` (una de las 4 macros de arriba) como parámetro.
`firmware/display.c` en esta carpeta queda como placeholder — ver ese
archivo.

## Errores comunes a evitar
- Sacar el reloj de píxel del reloj del sistema sin pasar por un PLL
  real — 25.175 MHz no es un divisor entero limpio de la mayoría de
  relojes de FPGA; hay que generarlo con el PLL de la ECP5 (como el
  ejemplo `pll/` del repo del curso), no con un contador simple.
- Actualizar el framebuffer a mitad de un frame que se está escaneando
  activamente → parpadeo/tearing visible. Si da tiempo en el proyecto,
  usar doble buffer (dibujar en uno mientras se muestra el otro).
- **Subestimar el tamaño del framebuffer** (ver la nota de arriba —
  sigue sin caber un framebuffer a 640×480 color completo aunque la
  ventana subió a 128 KB) — definir la resolución REAL de cada juego
  antes de dar por cerrado `FB_WIDTH`/`FB_HEIGHT` en `display_driver.v`.
- Tratar `framebuffer.v` como si fuera un periférico CSR (`cs`/`rd`/`wr`
  de un solo registro) — es memoria de dos puertos, igual que la BRAM.

## Estado
- [x] Módulo diseñado (`vga_timing.v`, `framebuffer.v`, `display_driver.v`)
- [x] Testbench escrito (`display_driver_TB.v`, básico)
- [ ] Módulo simulado y verificado (correr `make sim`)
- [ ] Módulo probado en hardware real (Colorlight 5A-75E)
- [x] Ventanas de framebuffer documentadas (oficiales, confirmadas)
- [ ] Resolución final de cada juego (`FB_WIDTH`/`FB_HEIGHT`) — punto de coordinación abierto con Grupo C y Grupo K
