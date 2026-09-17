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

## Esqueleto de implementación (punto de partida real)

```verilog
module nes_controller #(parameter N = 8) (
    input  wire clk, rst,
    output reg  latch,
    output reg  sh_clock,
    input  wire [N-1:0] data,
    output reg  [7:0] buttons [0:N-1],
    output reg  poll_done
);
    // Divisor de reloj para acercarse a ~12us por fase (ajustar segun
    // reloj real del sistema; a 25MHz, 12us = 300 ciclos)
    localparam integer HALF_PERIOD = 300;
    reg [9:0] counter = 0;
    reg [3:0] bit_index = 0;
    localparam LATCH_HIGH=0, LATCH_LOW=1, CLOCK_LOW=2, CLOCK_HIGH=3;
    reg [1:0] state = LATCH_HIGH;

    always @(posedge clk) begin
        poll_done <= 0;
        counter <= counter + 1;
        case (state)
            LATCH_HIGH: begin
                latch <= 1;
                if (counter == HALF_PERIOD) begin counter <= 0; state <= LATCH_LOW; end
            end
            LATCH_LOW: begin
                latch <= 0;
                // bit 0 (boton A) ya esta disponible en 'data' ahora mismo
                for (integer i = 0; i < N; i = i + 1) buttons[i][0] <= data[i];
                bit_index <= 1;
                if (counter == HALF_PERIOD) begin counter <= 0; state <= CLOCK_HIGH; end
            end
            CLOCK_HIGH: begin
                sh_clock <= 1;
                if (counter == HALF_PERIOD) begin counter <= 0; state <= CLOCK_LOW; end
            end
            CLOCK_LOW: begin
                sh_clock <= 0;
                for (integer i = 0; i < N; i = i + 1) buttons[i][bit_index] <= data[i];
                if (counter == HALF_PERIOD) begin
                    counter <= 0;
                    if (bit_index == 7) begin
                        poll_done <= 1; state <= LATCH_HIGH;
                    end else begin
                        bit_index <= bit_index + 1; state <= CLOCK_HIGH;
                    end
                end
            end
        endcase
    end
endmodule
```

Este ciclo completo (latch + 7 pulsos de clock) debe repetirse
continuamente, idealmente sincronizado con el refresco de video
(~60 Hz) para que la lectura de botones esté lista antes de dibujar
cada frame nuevo.

## API en C para el Grupo K

```c
// nes_controller.h
// bit0=A, bit1=B, bit2=Select, bit3=Start, bit4=Up, bit5=Down, bit6=Left, bit7=Right
#define NES_P1 (*(volatile unsigned int*)0x00060000)
#define NES_P2 (*(volatile unsigned int*)0x00060004)
// ... NES_P3 a NES_P8 igual, sumando 0x4 cada vez

#define BOTON_A      0x01
#define BOTON_B      0x02
#define BOTON_SELECT 0x04
#define BOTON_START  0x08
#define BOTON_ARRIBA 0x10
#define BOTON_ABAJO  0x20
#define BOTON_IZQ    0x40
#define BOTON_DER    0x80

int control_desconectado(unsigned int lectura) { return lectura == 0xFF; }
```

## Errores comunes a evitar
- Leer los botones UNA SOLA VEZ al iniciar en vez de continuamente —
  hay que re-leer cada control en cada frame, si no los movimientos del
  jugador no se reflejan.
- Invertir el orden de los 8 bits (es A, B, Select, Start, Up, Down,
  Left, Right — en ese orden exacto, no alfabético ni el que "parezca
  lógico").
- No usar el patrón "todos en 1" como señal real de desconexión (ver
  `docs/manejo_errores_y_seguridad.md`).

## Estado
- [ ] Módulo diseñado
- [ ] Módulo simulado (testbench)
- [ ] Módulo probado en hardware real (Colorlight 5A-75E)
- [ ] Mapa de registros/memoria documentado (ver arriba)
