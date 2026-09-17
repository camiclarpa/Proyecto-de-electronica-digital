# Grupo E — `perip_ps2kbd`

Controlador de teclado PS/2 (configuración/depuración del sistema).

> **Direcciones actualizadas 2026-09-16**: se confirmaron contra el
> mapa de memoria oficial del curso (antes eran un supuesto propio sin
> validar). Detalle en
> [`../../docs/decisiones_cerradas.md`](../../docs/decisiones_cerradas.md).

## Función en el proyecto

No es para jugar (eso lo hacen los 8 controles NES del Grupo G) — es
para que un adulto/desarrollador pueda configurar el sistema (ej.
escribir texto en un menú de administración, o depurar sin necesitar
los controles de juego).

## Estructura de esta carpeta

```
grupo_E_ps2_keyboard/
├── README.md                (este archivo)
├── diagramas/README.md      — trama PS/2 de 11 bits, secuencia de "tecla soltada"
├── rtl/
│   ├── Makefile               — `make sim` para correr la prueba
│   ├── perip_ps2kbd.v          — módulo real (receptor + registros)
│   └── perip_ps2kbd_TB.v       — testbench (genera tramas PS/2 reales)
└── firmware/
    ├── ps2_keyboard.h          — direcciones + macros de registro
    └── ps2_keyboard.c           — `kbd_tecla_disponible`, `kbd_leer_scancode`, `kbd_fue_soltada`
```

## Protocolo real

Bus de 2 líneas en colector abierto: `PS2_CLK` y `PS2_DATA`. El
**teclado es quien genera el reloj** (10–16.7 kHz), no la FPGA. Cada
tecla se envía como una trama de 11 bits: 1 bit de start (siempre 0),
8 bits de datos (LSB primero), 1 bit de paridad impar, 1 bit de stop
(siempre 1). El controlador captura cada bit en el flanco de bajada de
`PS2_CLK`. Ver el diagrama de trama en
[`diagramas/README.md`](diagramas/README.md).

- **Scan Code Set 2** (el que usan los teclados PS/2 por defecto).
- Al **soltar** una tecla, el teclado manda primero el byte `0xF0`
  (break code) y luego el scancode de esa tecla — el módulo retiene
  ese estado y publica `key_release=1` junto con el scancode
  correspondiente.
- Teclas especiales (flechas, etc.) llevan un prefijo `0xE0` antes del
  scancode; el módulo lo entrega como un byte crudo más — la
  traducción de la secuencia completa a una tecla lógica se hace en
  **software** (Grupo K).
- `ps2_clk`/`ps2_data` vienen de un dispositivo externo asíncrono al
  reloj del sistema: `perip_ps2kbd.v` incluye su propio sincronizador
  de doble flip-flop antes de usarlos, para evitar metaestabilidad.

## Tabla de registros (CSR)

Offsets relativos a la base de este periférico. La base real y la
ventana completa están en
[`../../docs/mapa_memoria.md`](../../docs/mapa_memoria.md) — **oficial,
confirmada contra el repositorio del profesor** (antes era un supuesto
propio sin validar).

| Registro | Offset | R/W | Descripción |
|---|---|---|---|
| `KBD_DATA` | `0x00` | R | bits[7:0] = scancode, bit8 = `key_release` (1 si venía precedido de `0xF0`) |
| `KBD_STATUS` | `0x04` | R | bit0 = `valid` (scancode nuevo disponible, se limpia al leer `KBD_DATA`) |

Base oficial: **`0x00430000`** (ventana `0x430000`–`0x43FFFF`, 64KB).

## Integración en el SoC

`perip_ps2kbd` recibe **`addr` como offset local** (ya restada la base
`0x430000`) — el decodificador central del SoC es responsable de:
1. Comparar la dirección del CPU contra la ventana `0x430000–0x43FFFF`.
2. Generar `cs = 1` solo cuando la dirección cae en esa ventana.
3. Conectar `addr = direccion_cpu - 0x430000` al puerto `addr` del
   módulo (mismo patrón que usa `perip_uart` del Grupo B con su base
   `0x400000`).

## Simulación

```bash
cd rtl
make sim
```

Corre el testbench `perip_ps2kbd_TB.v`: genera tramas PS/2 reales de 11
bits sobre `ps2_clk`/`ps2_data` (simulando al teclado como maestro del
reloj), incluyendo el caso de scancode normal y el caso de "tecla
soltada" (prefijo `0xF0`), y verifica que `KBD_DATA`/`KBD_STATUS`
queden correctos.

## API en C para el Grupo K

Ver [`firmware/ps2_keyboard.h`](firmware/ps2_keyboard.h) y
[`firmware/ps2_keyboard.c`](firmware/ps2_keyboard.c):

```c
int           kbd_tecla_disponible(void); // consulta KBD_STATUS.valid
unsigned char kbd_leer_scancode(void);    // lee KBD_DATA[7:0]
int           kbd_fue_soltada(void);      // lee KBD_DATA[8]
```

El decodificado de scancode → carácter/tecla (ej. traducir Set 2 a
ASCII, o manejar el prefijo `0xE0` de teclas extendidas) se hace en
**software**, no en el módulo Verilog — el módulo solo entrega el
scancode crudo. Uso principal: menú de configuración/depuración, no
gameplay.

## Errores comunes a evitar
- No sincronizar `ps2_clk`/`ps2_data` (metaestabilidad) → lecturas
  fantasma esporádicas, muy difíciles de depurar porque no son
  reproducibles siempre igual. El módulo ya incluye el sincronizador
  de doble flip-flop internamente — no conectar los pines PS/2 crudos
  a otra lógica sin pasar por él.
- Olvidar el manejo del prefijo `0xF0` (soltar tecla) — sin esto, el
  sistema "cree" que una tecla queda presionada para siempre.
- Usar la dirección ABSOLUTA (`0x430000 + offset`) dentro del propio
  módulo `perip_ps2kbd.v` — el módulo solo debe conocer el offset; la
  base la maneja el decodificador central del SoC.

## Estado
- [x] Módulo diseñado
- [x] Testbench escrito (`perip_ps2kbd_TB.v`)
- [ ] Módulo simulado y verificado (correr `make sim`)
- [ ] Módulo probado en hardware real (Colorlight 5A-75E)
- [x] Mapa de registros documentado (offsets arriba, base oficial confirmada)
