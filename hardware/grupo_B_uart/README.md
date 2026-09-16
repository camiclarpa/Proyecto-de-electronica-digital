# Grupo B — uart.v

Controlador UART (comunicación serial con el exterior / depuración).

## Función en el proyecto

Canal de depuración del sistema: permite que el Grupo K imprima
mensajes de estado/error desde el software (útil para probar cada
juego sin necesitar la pantalla funcionando todavía) y sirve de puente
hacia un PC o el ESP32 (como en el ejemplo `femtoriscv` del curso).

## Protocolo real

UART asíncrona estándar: 1 bit de start, 8 bits de datos (LSB primero),
sin paridad, 1 bit de stop. Velocidad recomendada: **57600 baudios**
(la misma que usa el ejemplo del curso hacia el puente ESP32; si se
comunica directo a un PC vía FT232RL, 115200 también es viable).

## Interfaz esperada (puertos del módulo)

```verilog
module uart #(parameter CLK_FREQ = 25000000, parameter BAUD = 57600) (
    input  wire       clk,
    input  wire       rst,
    output wire       tx,
    input  wire       rx,
    input  wire [7:0] tx_data,
    input  wire        tx_write,   // pulso: iniciar envio de tx_data
    output wire        tx_busy,
    output wire [7:0]  rx_data,
    output wire         rx_valid   // se pone en 1 un ciclo cuando llega un byte nuevo
);
```

## Mapa de memoria (PROPUESTO — validar contra el decodificador real `chip_select.v`)

| Dirección | Nombre | Lectura/Escritura | Descripción |
|---|---|---|---|
| `0x00010000` | UART_DATA | R/W | Escribir: byte a transmitir. Leer: último byte recibido. |
| `0x00010004` | UART_STATUS | R | bit0 = tx_busy, bit1 = rx_valid (dato nuevo disponible) |

## Requisitos desde el software (Grupo K)
- Función `uart_putc(char c)`: espera a que `tx_busy==0`, escribe en `UART_DATA`.
- Función `uart_getc()`: sondea `UART_STATUS.bit1`, si hay dato lee `UART_DATA`.
- Usado principalmente para `printf`-style de depuración mientras se
  prueba cada juego antes de tener pantalla real conectada.

## Estado
- [ ] Módulo diseñado
- [ ] Módulo simulado (testbench)
- [ ] Módulo probado en hardware real (Colorlight 5A-75E)
- [ ] Mapa de registros/memoria documentado (ver arriba)
