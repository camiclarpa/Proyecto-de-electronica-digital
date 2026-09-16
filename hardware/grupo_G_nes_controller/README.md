# Grupo G — nes_controller.v

Lectura de los 8 controles tipo NES (2 por pantalla, entradas de juego).

## Función en el proyecto

**Es el módulo más crítico del gameplay**: de aquí sale toda la entrada
del jugador para los 4 juegos (Pong, Space Invaders, Snake, Carrito).

## Protocolo real (controlador NES original)

3 líneas por control: `LATCH`, `CLOCK`, `DATA` (más VCC/GND). El host
(la FPGA) es quien controla el ritmo:

1. La FPGA sube `LATCH` por ~12 µs. Esto hace que el control **cargue**
   el estado actual de sus 8 botones en un registro de desplazamiento
   interno (shift register 4021 en el hardware original).
2. Al bajar `LATCH`, el primer bit (botón **A**) ya está disponible en
   `DATA`.
3. La FPGA manda 7 pulsos más de `CLOCK` (periodo ~12 µs, aunque
   funciona bien incluso más rápido en la práctica); en cada flanco de
   bajada de `CLOCK` el control saca el siguiente bit en `DATA`.
4. **Orden real de los 8 bits**: `A, B, Select, Start, Up, Down, Left, Right`.
5. Cada línea `DATA` es independiente por control — con 8 controles se
   necesitan 8 líneas `DATA`, pero `LATCH` y `CLOCK` **se pueden
   compartir entre todos** (se leen los 8 en paralelo al mismo tiempo).
   Esto simplifica mucho el cableado: 2 líneas comunes + 8 líneas de
   datos = 10 pines totales, no 24.

## Interfaz esperada (puertos del módulo)

```verilog
module nes_controller #(parameter N = 8) (
    input  wire clk, rst,
    output wire latch,
    output wire sh_clock,
    input  wire [N-1:0] data,       // una linea DATA por control
    output reg  [7:0] buttons [0:N-1], // 8 bits de botones por cada uno de los N controles
    output reg  poll_done            // pulso: los N controles ya se leyeron este ciclo
);
```

- Debe re-leer los 8 controles periódicamente (ej. cada frame de video,
  ~60 Hz) y actualizar `buttons[]`, no solo una vez.
- Un control desconectado normalmente lee todo en 1 (por el pull-up de
  la línea `DATA` sin nada conectado) — el software debe tratar
  "todos los botones en 1 todo el tiempo" como señal de "control no
  conectado" (ver `docs/manejo_errores_y_seguridad.md`).

## Mapa de memoria (PROPUESTO — validar contra el decodificador real `chip_select.v`)

| Dirección | Nombre | Lectura/Escritura | Descripción |
|---|---|---|---|
| `0x00060000` | NES_P1 | R | Botones del control 1 (Pantalla 1, jugador A) — bit0=A,1=B,2=Select,3=Start,4=Up,5=Down,6=Left,7=Right |
| `0x00060004` | NES_P2 | R | Control 2 (Pantalla 1, jugador B) |
| `0x00060008` | NES_P3 | R | Control 3 (Pantalla 2, jugador A) |
| `0x0006000C` | NES_P4 | R | Control 4 (Pantalla 2, jugador B) |
| `0x00060010` | NES_P5 | R | Control 5 (Pantalla 3, jugador A) |
| `0x00060014` | NES_P6 | R | Control 6 (Pantalla 3, jugador B) |
| `0x00060018` | NES_P7 | R | Control 7 (Pantalla 4, jugador A) |
| `0x0006001C` | NES_P8 | R | Control 8 (Pantalla 4, jugador B) |

## Requisitos desde el software (Grupo K)
- Cada juego solo necesita leer los 2 registros correspondientes a SU
  pantalla (ej. el juego en Pantalla 1 solo lee `NES_P1`/`NES_P2`).
- Bit "todos en 1 sostenido" = control desconectado → mostrar estado
  visual de error en esa pantalla, sin afectar a las otras 3 (ver
  seguridad física).

## Estado
- [ ] Módulo diseñado
- [ ] Módulo simulado (testbench)
- [ ] Módulo probado en hardware real (Colorlight 5A-75E)
- [ ] Mapa de registros/memoria documentado (ver arriba)
