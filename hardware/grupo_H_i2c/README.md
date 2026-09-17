# Grupo H — `perip_i2c`

Maestro I2C para periféricos auxiliares (ej. brillo de pantallas).

> **Dirección actualizada 2026-09-16**: se confirmó contra el mapa de
> memoria oficial del curso (antes era un supuesto propio sin validar).
> Detalle en
> [`../../docs/decisiones_cerradas.md`](../../docs/decisiones_cerradas.md).

## Función en el proyecto

Controla periféricos que no necesitan tanto ancho de banda como video o
audio, típicamente configuración: por ejemplo, si las pantallas o algún
driver de brillo/contraste se controlan por I2C, este módulo es el que
manda esos comandos de configuración al iniciar el sistema (y
opcionalmente cuando el usuario ajuste el brillo).

## Estructura de esta carpeta

```
grupo_H_i2c/
├── README.md              (este archivo)
├── diagramas/README.md    — trama START/ADDR/ACK/DATA/ACK/STOP, bloques internos
├── rtl/
│   ├── Makefile            — `make sim` para correr la prueba
│   ├── perip_i2c.v          — módulo real (maestro I2C, 1 byte por transacción)
│   └── perip_i2c_TB.v       — testbench (esclavo simulado: escritura + lectura + clock stretch)
└── firmware/
    ├── i2c.h                — direcciones + macros de registro
    └── i2c.c                 — `i2c_escribir`, `i2c_leer`
```

## Protocolo real (I2C)

2 líneas en colector abierto compartidas por todos los dispositivos del
bus: `SCL` (reloj) y `SDA` (datos). El maestro genera:
- **Condición START**: `SDA` baja mientras `SCL` está alto.
- Byte de dirección (7 bits) + bit R/W, luego cada byte de datos, cada
  uno seguido de un bit de ACK/NACK del otro lado.
- **Condición STOP**: `SDA` sube mientras `SCL` está alto.

Velocidad recomendada: **100 kHz (modo estándar)** — suficiente para
comandos de configuración poco frecuentes, no hace falta 400 kHz.

Como las líneas son de colector abierto, el maestro **nunca las lleva
a 1 directamente**: las libera (alta impedancia) y confía en el pull-up
externo. Esto es justo lo que permite el **clock stretching**: un
esclavo lento puede retener `SCL` en 0 un rato más para pedir tiempo, y
el maestro debe esperar a leerla realmente en 1 antes de seguir — ver
el diagrama y el detalle de implementación en
[`diagramas/README.md`](diagramas/README.md).

## Tabla de registros (CSR)

Offsets relativos a la base de este periférico. La base real y la
ventana completa están en
[`../../docs/mapa_memoria.md`](../../docs/mapa_memoria.md) — **oficial,
confirmada contra el repositorio del profesor**: ventana
`0x460000–0x46FFFF` (64KB).

| Registro | Offset | R/W | Descripción |
|---|---|---|---|
| `I2C_ADDR` | `0x00` | W | Dirección del esclavo (7 bits) |
| `I2C_DATA` | `0x04` | R/W | Byte a escribir / último byte leído |
| `I2C_CTRL` | `0x08` | W | bit0 = start, bit1 = rw (1=lectura) |
| `I2C_STATUS` | `0x0C` | R | bit0 = busy, bit1 = ack_error |

## Integración en el SoC

`perip_i2c` recibe **`addr` como offset local** (ya restada la base
`0x460000`) — el decodificador central del SoC es responsable de:
1. Comparar la dirección del CPU contra la ventana `0x460000–0x46FFFF`.
2. Generar `cs = 1` solo cuando la dirección cae en esa ventana.
3. Conectar `addr = direccion_cpu - 0x460000` al puerto `addr[3:0]` del
   módulo (mismo patrón que usa `perip_uart` en
   [`../grupo_B_uart/README.md`](../grupo_B_uart/README.md) con su
   propia base).

`scl` y `sda` deben salir directo a pines FPGA configurados como
colector abierto real (o con el buffer tri-state correspondiente) — la
FPGA no puede manejar la línea a 1 activamente, solo liberarla.

## Simulación

```bash
cd rtl
make sim
```

Corre el testbench `perip_i2c_TB.v`, que modela un esclavo I2C en la
dirección `0x50`: ejercita una transacción de **escritura** (verifica
que el esclavo reciba el byte correcto y responda ACK) y una de
**lectura** (verifica que el maestro reciba el byte que manda el
esclavo), y además fuerza un **clock stretch** en el primer bit de la
transacción para comprobar que el maestro espera de verdad a que `SCL`
suba en vez de asumirlo.

## API en C para el Grupo K

Ver [`firmware/i2c.h`](firmware/i2c.h) y
[`firmware/i2c.c`](firmware/i2c.c):

```c
int i2c_escribir(uint8_t addr7, uint8_t dato);       // 0 = ACK, -1 = ack_error
int i2c_leer(uint8_t addr7, uint8_t *dato_leido);     // 0 = ACK, -1 = ack_error
```

Uso puntual, no en el bucle principal del juego: se usa al inicio del
sistema (configuración) o cuando el usuario cambia el brillo desde el
menú, no en cada frame.

## Errores comunes a evitar
- No implementar el *clock stretching* (el esclavo puede mantener
  `SCL` baja para pedir más tiempo) — si el maestro asume que `SCL`
  ya subió apenas la libera, en vez de volver a leerla, algunos
  periféricos I2C reales fallarán de forma intermitente.
- Olvidar liberar `SDA` (alta impedancia) cuando no se está
  transmitiendo — si el maestro maneja `SDA` como salida siempre,
  nunca puede leer el ACK del esclavo ni los bytes en modo lectura.
- Cambiar `SDA` mientras `SCL` está en alto fuera de las condiciones
  START/STOP — el bus lo interpreta como una condición START o STOP
  espuria y rompe la transacción en curso.
- Usar la dirección ABSOLUTA (`0x460000 + offset`) dentro del propio
  módulo `perip_i2c.v` — el módulo solo debe conocer el offset; la
  base la maneja el decodificador central del SoC.

## Estado
- [x] Módulo diseñado
- [x] Testbench escrito (`perip_i2c_TB.v`)
- [x] Módulo simulado y verificado (`make sim` — PASS en escritura, lectura y clock stretch)
- [ ] Módulo probado en hardware real (Colorlight 5A-75E)
- [x] Mapa de registros documentado (offsets arriba, base oficial confirmada)
