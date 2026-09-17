# Grupo H — i2c_master.v

Maestro I2C para periféricos auxiliares (ej. brillo de pantallas).

## Función en el proyecto

Controla periféricos que no necesitan tanto ancho de banda como video o
audio, típicamente configuración: por ejemplo, si las pantallas o algún
driver de brillo/contraste se controlan por I2C, este módulo es el que
manda esos comandos de configuración al iniciar el sistema (y
opcionalmente cuando el usuario ajuste el brillo).

## Protocolo real (I2C)

2 líneas en colector abierto compartidas por todos los dispositivos del
bus: `SCL` (reloj) y `SDA` (datos). El maestro genera:
- **Condición START**: `SDA` baja mientras `SCL` está alto.
- Byte de dirección (7 bits) + bit R/W, luego cada byte de datos,
  cada uno seguido de un bit de ACK/NACK del esclavo.
- **Condición STOP**: `SDA` sube mientras `SCL` está alto.

Velocidad recomendada: **100 kHz (modo estándar)** — suficiente para
comandos de configuración poco frecuentes, no hace falta 400 kHz.

## Interfaz esperada (puertos del módulo)

```verilog
module i2c_master #(parameter CLK_FREQ = 25000000, parameter I2C_FREQ = 100000) (
    input  wire       clk, rst,
    inout  wire        scl, sda,
    input  wire [6:0]  slave_addr,
    input  wire [7:0]  data_in,
    output reg  [7:0]  data_out,
    input  wire          rw,        // 0 = escritura, 1 = lectura
    input  wire          start,     // pulso: iniciar transaccion
    output reg            busy,
    output reg            ack_error  // 1 si el esclavo no respondio ACK
);
```

## Mapa de memoria (PROPUESTO — validar contra el decodificador real `chip_select.v`)

| Dirección | Nombre | Lectura/Escritura | Descripción |
|---|---|---|---|
| `0x00070000` | I2C_ADDR | W | Dirección del esclavo (7 bits) |
| `0x00070004` | I2C_DATA | R/W | Byte a escribir / último byte leído |
| `0x00070008` | I2C_CTRL | W | bit0 = start, bit1 = rw (1=lectura) |
| `0x0007000C` | I2C_STATUS | R | bit0 = busy, bit1 = ack_error |

## Requisitos desde el software (Grupo K)
- Uso puntual, no en el bucle principal del juego: se usa al inicio del
  sistema (configuración) o cuando el usuario cambia el brillo desde el
  menú, no en cada frame.

## Esqueleto de implementación (máquina de estados real)

```verilog
module i2c_master #(parameter CLK_FREQ = 25000000, parameter I2C_FREQ = 100000) (
    input  wire       clk, rst,
    output reg        scl,
    inout  wire       sda,
    input  wire [6:0] slave_addr,
    input  wire [7:0] data_in,
    output reg  [7:0] data_out,
    input  wire       rw, start,
    output reg        busy, ack_error
);
    localparam integer DIV = CLK_FREQ / (I2C_FREQ * 4); // 4 fases por bit
    localparam IDLE=0, START=1, ADDR=2, RW_ACK=3, DATA=4, DATA_ACK=5, STOP=6;
    reg [2:0] state = IDLE;
    reg sda_out, sda_oe; // control de colector abierto real
    assign sda = sda_oe ? sda_out : 1'bz;

    // Nota: esta es la estructura de estados; el detalle fino de generar
    // START (SDA baja con SCL alto) y STOP (SDA sube con SCL alto)
    // requiere sub-fases dentro de cada estado — implementar con
    // cuidado siguiendo el diagrama de tiempos del protocolo I2C real.
endmodule
```

## API en C para el Grupo K

```c
// i2c.h
#define I2C_ADDR   (*(volatile unsigned int*)0x00070000)
#define I2C_DATA   (*(volatile unsigned int*)0x00070004)
#define I2C_CTRL   (*(volatile unsigned int*)0x00070008)
#define I2C_STATUS (*(volatile unsigned int*)0x0007000C)

void i2c_escribir(unsigned char addr7, unsigned char dato) {
    I2C_ADDR = addr7;
    I2C_DATA = dato;
    I2C_CTRL = 0x1; // start=1, rw=0
    while (I2C_STATUS & 0x1) {} // espera busy==0
}
```

## Errores comunes a evitar
- No implementar el *clock stretching* (el esclavo puede mantener
  `SCL` baja para pedir más tiempo) — si el diseño lo ignora, algunos
  periféricos I2C reales fallarán de forma intermitente.
- Olvidar liberar `SDA` (alta impedancia) cuando no se está
  transmitiendo — si el maestro maneja `SDA` como salida siempre, nunca
  puede leer el ACK del esclavo.

## Estado
- [ ] Módulo diseñado
- [ ] Módulo simulado (testbench)
- [ ] Módulo probado en hardware real (Colorlight 5A-75E)
- [ ] Mapa de registros/memoria documentado (ver arriba)
