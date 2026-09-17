# Grupo B — `perip_uart`

Controlador UART (comunicación serial con el exterior / depuración).

> **Direcciones actualizadas 2026-09-16**: se confirmaron contra el
> mapa de memoria oficial del curso (antes eran un supuesto propio sin
> validar). Detalle en
> [`../../docs/decisiones_cerradas.md`](../../docs/decisiones_cerradas.md).

## Función en el proyecto

Canal de depuración del sistema: permite que el Grupo K imprima
mensajes de estado/error desde el software (útil para probar cada
juego sin necesitar la pantalla funcionando todavía) y sirve de puente
hacia un PC o el ESP32 (como en el ejemplo `femtorv32` del curso).

## Estructura de esta carpeta

```
grupo_B_uart/
├── README.md              (este archivo)
├── diagramas/README.md    — trama UART, diagrama de bloques interno
├── rtl/
│   ├── Makefile            — `make sim` para correr la prueba
│   ├── perip_uart.v         — módulo real (TX + RX + registros)
│   └── perip_uart_TB.v      — testbench (loopback tx→rx)
└── firmware/
    ├── uart.h               — direcciones + macros de registro
    └── uart.c                — `uart_putc`, `uart_getc`
```

## Protocolo real

UART asíncrona estándar: 1 bit de start, 8 bits de datos (LSB primero),
sin paridad, 1 bit de stop. Velocidad recomendada: **57600 baudios**
(la misma que usa el ejemplo del curso hacia el puente ESP32; si se
comunica directo a un PC vía FT232RL, 115200 también es viable). Ver
el diagrama de trama en [`diagramas/README.md`](diagramas/README.md).

## Tabla de registros (CSR)

Offsets relativos a la base de este periférico. La base real y la
ventana completa están en
[`../../docs/mapa_memoria.md`](../../docs/mapa_memoria.md) — **oficial,
confirmada contra el repositorio del profesor** (antes era un
supuesto propio sin validar).

| Registro | Offset | R/W | Descripción |
|---|---|---|---|
| `UART_DATA` | `0x00` | R/W | Escribir: byte a transmitir. Leer: último byte recibido |
| `UART_STATUS` | `0x04` | R | bit0 = `tx_busy`, bit1 = `rx_valid` (dato nuevo disponible) |

## Integración en el SoC

`perip_uart` recibe **`addr` como offset local** (ya restada la base
`0x400000`) — el decodificador central del SoC es responsable de:
1. Comparar la dirección del CPU contra la ventana `0x400000–0x40FFFF`.
2. Generar `cs = 1` solo cuando la dirección cae en esa ventana.
3. Conectar `addr = direccion_cpu - 0x400000` al puerto `addr` del
   módulo (ver el ejemplo `perip_blink` del profesor, que usa el mismo
   patrón con su propia base `0x500000`).

## Simulación

```bash
cd rtl
make sim
```

Corre el testbench `perip_uart_TB.v`: escribe un byte en `UART_DATA`,
dejando que se transmita y se reciba de vuelta por loopback (`tx`
conectado directo a `rx`), y verifica que el byte recibido coincida.

## API en C para el Grupo K

Ver [`firmware/uart.h`](firmware/uart.h) y
[`firmware/uart.c`](firmware/uart.c):

```c
void uart_putc(char c);          // espera tx_busy==0, escribe UART_DATA
int  uart_getc_available(void);  // consulta rx_valid
char uart_getc(void);            // lee UART_DATA
```

Usado principalmente para `printf`-style de depuración mientras se
prueba cada juego antes de tener pantalla real conectada.

## Errores comunes a evitar
- Calcular mal el divisor de baudios (`DIV`) — si el reloj real de la
  FPGA no es exactamente el asumido, el baud rate se corre y se leen
  bytes basura. Verificar el reloj real que entrega el PLL antes de
  fijar `CLK_FREQ`.
- Muestrear el bit de start apenas se detecta, sin esperar medio
  periodo — produce lecturas erráticas cerca de los bordes de cada bit.
- Usar la dirección ABSOLUTA (`0x400000 + offset`) dentro del propio
  módulo `perip_uart.v` — el módulo solo debe conocer el offset; la
  base la maneja el decodificador central del SoC.

## Estado
- [x] Módulo diseñado
- [x] Testbench escrito (`perip_uart_TB.v`)
- [ ] Módulo simulado y verificado (correr `make sim`)
- [ ] Módulo probado en hardware real (Colorlight 5A-75E)
- [x] Mapa de registros documentado (offsets arriba, base oficial confirmada)
