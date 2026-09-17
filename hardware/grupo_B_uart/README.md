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

## Esqueleto de implementación (transmisor, punto de partida real)

```verilog
module uart_tx #(parameter CLK_FREQ = 25000000, parameter BAUD = 57600) (
    input  wire       clk, rst,
    input  wire [7:0] data,
    input  wire        write,
    output reg          busy,
    output reg          tx
);
    localparam integer DIV = CLK_FREQ / BAUD;
    reg [12:0] clk_count = 0;
    reg [3:0]  bit_index = 0;
    reg [9:0]  shift_reg = 10'b1111111111; // reposo = todo en 1

    always @(posedge clk) begin
        if (rst) begin
            tx <= 1'b1; busy <= 0; clk_count <= 0; bit_index <= 0;
        end else if (write && !busy) begin
            shift_reg <= {1'b1, data, 1'b0}; // stop, datos LSB-first, start
            busy <= 1; clk_count <= 0; bit_index <= 0;
        end else if (busy) begin
            if (clk_count == DIV-1) begin
                clk_count <= 0;
                tx <= shift_reg[0];
                shift_reg <= {1'b1, shift_reg[9:1]};
                bit_index <= bit_index + 1;
                if (bit_index == 9) busy <= 0;
            end else clk_count <= clk_count + 1;
        end
    end
endmodule
```

El receptor (`uart_rx`) es el mismo principio al revés: detectar el
flanco de bajada del bit de start en `rx`, esperar medio periodo de bit
para muestrear en el centro de cada bit (evita leer justo en el borde,
donde la señal puede no haberse estabilizado).

## API en C para el Grupo K

```c
// uart.h
#define UART_DATA   (*(volatile unsigned int*)0x00010000)
#define UART_STATUS (*(volatile unsigned int*)0x00010004)

void uart_putc(char c) {
    while (UART_STATUS & 0x1) {} // espera tx_busy == 0
    UART_DATA = (unsigned int) c;
}

int uart_getc_available(void) { return UART_STATUS & 0x2; }
char uart_getc(void) { return (char) UART_DATA; }
```

## Errores comunes a evitar
- Calcular mal el divisor de baudios (`DIV`) — si el reloj real de la
  FPGA no es exactamente el asumido, el baud rate se corre y se leen
  bytes basura. Verificar el reloj real que entrega el PLL antes de
  fijar `CLK_FREQ`.
- Muestrear el bit de start apenas se detecta, sin esperar medio
  periodo — produce lecturas erráticas cerca de los bordes de cada bit.

## Estado
- [ ] Módulo diseñado
- [ ] Módulo simulado (testbench)
- [ ] Módulo probado en hardware real (Colorlight 5A-75E)
- [ ] Mapa de registros/memoria documentado (ver arriba)
