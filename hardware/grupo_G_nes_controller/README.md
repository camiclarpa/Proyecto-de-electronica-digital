# Grupo G — `perip_nes`

Lectura de los 8 controles tipo NES (2 por pantalla, entradas de juego).

> **Dirección actualizada 2026-09-16**: se confirmó contra el mapa de
> memoria oficial del curso (antes era un supuesto propio sin validar).
> Detalle en
> [`../../docs/decisiones_cerradas.md`](../../docs/decisiones_cerradas.md).

## Función en el proyecto

**Es el módulo más crítico del gameplay**: de aquí sale toda la entrada
del jugador para los 4 juegos (Pong, Space Invaders, Snake, Carrito).

## Estructura de esta carpeta

```
grupo_G_nes_controller/
├── README.md              (este archivo)
├── diagramas/README.md    — secuencia Latch/Clock, diagrama de bloques
├── rtl/
│   ├── Makefile            — `make sim` para correr la prueba
│   ├── perip_nes.v          — módulo real (FSM Latch/Clock + 8 registros)
│   └── perip_nes_TB.v       — testbench (simula 2 controles: P1 con patrón, P2 desconectado)
└── firmware/
    ├── nes.h                — direcciones + macros de registro
    └── nes.c                 — `nes_leer`, `nes_desconectado`
```

## Protocolo real (controlador NES original)

3 líneas por control: `LATCH`, `CLOCK`, `DATA` (más VCC/GND). El host
(la FPGA) es quien controla el ritmo:

1. La FPGA sube `LATCH` por ~12 µs. Esto hace que el control **cargue**
   el estado actual de sus 8 botones en un registro de desplazamiento
   interno (shift register 4021 en el hardware original).
2. Al bajar `LATCH`, el primer bit (botón **A**) ya está disponible en
   `DATA`.
3. La FPGA manda 7 pulsos más de `CLOCK` (periodo ~12 µs); en cada
   flanco de bajada de `CLOCK` el control saca el siguiente bit en
   `DATA`.
4. **Orden real de los 8 bits**: `A, B, Select, Start, Up, Down, Left, Right`.
5. Cada línea `DATA` es independiente por control — con 8 controles se
   necesitan 8 líneas `DATA`, pero `LATCH` y `CLOCK` **se comparten
   entre todos** (se leen los 8 en paralelo al mismo tiempo). Esto
   simplifica mucho el cableado: 2 líneas comunes + 8 líneas de datos =
   10 pines totales, no 24.

Ver el diagrama de la secuencia en
[`diagramas/README.md`](diagramas/README.md).

## Tabla de registros (CSR)

Offsets relativos a la base de este periférico. La base real y la
ventana completa están en
[`../../docs/mapa_memoria.md`](../../docs/mapa_memoria.md) — **oficial,
confirmada contra el repositorio del profesor**: ventana
`0x450000–0x45FFFF` (64KB).

| Registro | Offset | R/W | Descripción |
|---|---|---|---|
| `NES_P1` | `0x00` | R | Pantalla 1, jugador A |
| `NES_P2` | `0x04` | R | Pantalla 1, jugador B |
| `NES_P3` | `0x08` | R | Pantalla 2, jugador A |
| `NES_P4` | `0x0C` | R | Pantalla 2, jugador B |
| `NES_P5` | `0x10` | R | Pantalla 3, jugador A |
| `NES_P6` | `0x14` | R | Pantalla 3, jugador B |
| `NES_P7` | `0x18` | R | Pantalla 4, jugador A |
| `NES_P8` | `0x1C` | R | Pantalla 4, jugador B |

Bits de cada registro: `bit0`=A, `bit1`=B, `bit2`=Select, `bit3`=Start,
`bit4`=Up, `bit5`=Down, `bit6`=Left, `bit7`=Right.

## Integración en el SoC

`perip_nes` recibe **`addr` como offset local** (ya restada la base
`0x450000`) — el decodificador central del SoC es responsable de:
1. Comparar la dirección del CPU contra la ventana `0x450000–0x45FFFF`.
2. Generar `cs = 1` solo cuando la dirección cae en esa ventana.
3. Conectar `addr = direccion_cpu - 0x450000` al puerto `addr[4:0]` del
   módulo (mismo patrón que usa `perip_uart` en
   [`../grupo_B_uart/README.md`](../grupo_B_uart/README.md) con su
   propia base).

## Simulación

```bash
cd rtl
make sim
```

Corre el testbench `perip_nes_TB.v`: simula 2 controles conectados por
sus líneas `DATA` (control 1 con un patrón de botones fijo `0xB5`,
control 2 "desconectado" = todo en 1 por el pull-up) y verifica que
`NES_P1` y `NES_P2` se lean correctamente a través del bus tras un
ciclo completo de poll (Latch + 7 pulsos de Clock).

## API en C para el Grupo K

Ver [`firmware/nes.h`](firmware/nes.h) y
[`firmware/nes.c`](firmware/nes.c):

```c
uint8_t nes_leer(int pantalla, int jugador); // pantalla 1-4, jugador 0=A,1=B
int     nes_desconectado(uint8_t lectura);   // todo en 1 sostenido = sin conectar
```

Cada juego solo necesita leer los 2 registros correspondientes a SU
pantalla (ej. el juego en Pantalla 1 solo lee `NES_P1`/`NES_P2`).

## Errores comunes a evitar
- Leer los botones UNA SOLA VEZ al iniciar en vez de continuamente —
  hay que re-leer cada control en cada frame (~60 Hz), si no los
  movimientos del jugador no se reflejan.
- Invertir el orden de los 8 bits (es A, B, Select, Start, Up, Down,
  Left, Right — en ese orden exacto, no alfabético ni el que "parezca
  lógico").
- No tratar el patrón "todos en 1 sostenido" como señal real de
  desconexión (ver `docs/manejo_errores_y_seguridad.md`) — mostrar
  estado visual de error en esa pantalla sin afectar a las otras 3.
- Usar la dirección ABSOLUTA (`0x450000 + offset`) dentro del propio
  módulo `perip_nes.v` — el módulo solo debe conocer el offset; la
  base la maneja el decodificador central del SoC.

## Estado
- [x] Módulo diseñado
- [x] Testbench escrito (`perip_nes_TB.v`)
- [x] Módulo simulado y verificado (`make sim` — PASS en ambos casos)
- [ ] Módulo probado en hardware real (Colorlight 5A-75E)
- [x] Mapa de registros documentado (offsets arriba, base oficial confirmada)
