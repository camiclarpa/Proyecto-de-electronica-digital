# Grupo I — `perip_i2s`

Transmisor de audio I2S: 4 salidas de sonido independientes, una por
pantalla/juego.

> **Dirección actualizada 2026-09-16**: se confirmó contra el mapa de
> memoria oficial del curso (antes era un supuesto propio sin
> validar). Detalle en
> [`../../docs/decisiones_cerradas.md`](../../docs/decisiones_cerradas.md).

## Función en el proyecto

Genera el sonido de cada uno de los 4 juegos, de forma independiente
(el sonido de Pong en la Pantalla 1 no debe mezclarse con el de Snake
en la Pantalla 3).

## Cómo se resuelve el audio de las 4 pantallas (pregunta ya cerrada)

La solución real: **4 instancias independientes** del módulo `i2s_tx`
(una por pantalla/juego), cada una con su propio DAC externo I2S. No
hay que mezclar audio en software — cada juego solo le habla a SU
canal (`AUDIO1_DATA`…`AUDIO4_DATA`), sin saber que existen los otros 3.
Esto es consistente con el requisito de aislamiento de fallos: si el
audio de una pantalla falla, las otras 3 siguen sonando normal (ver
[`docs/decisiones_cerradas.md`](../../docs/decisiones_cerradas.md#preguntas-originales-del-readme-ya-resueltas)).

(Alternativa descartada: mezclar las 4 señales en software antes de un
único I2S — más complejo y no aporta nada frente al requisito real de
"4 salidas de sonido independientes".)

## Estructura de esta carpeta

```
grupo_I_i2s/
├── README.md              (este archivo)
├── diagramas/README.md    — trama I2S (BCLK/LRCLK/SDATA), diagrama de los 4 canales
├── rtl/
│   ├── Makefile
│   ├── perip_i2s.v          — módulo real: interfaz CSR + 4× i2s_tx
│   └── perip_i2s_TB.v        — testbench (arranca canal 1, verifica aislamiento de 2-4)
└── firmware/
    ├── i2s.h                 — direcciones + macros de registro
    └── i2s.c                  — `i2s_write1..4`, `i2s_reproducir_efecto`
```

## Protocolo real (I2S)

3 líneas por canal: `BCLK` (bit clock), `LRCLK`/`WS` (word select:
0=canal izquierdo, 1=canal derecho), `SDATA` (datos, **MSB primero**).
Formato recomendado para este proyecto: **16 bits, mono o estéreo
simple, 8–16 kHz de frecuencia de muestreo** (más que suficiente para
efectos de sonido de videojuego retro — no hace falta calidad de
música, y una frecuencia baja simplifica mucho el diseño y el tamaño de
los assets de audio en la flash). Ver el diagrama de trama en
[`diagramas/README.md`](diagramas/README.md).

## Tabla de registros (CSR)

Offsets relativos a la base de este periférico. La base real y la
ventana completa están en
[`../../docs/mapa_memoria.md`](../../docs/mapa_memoria.md) — **oficial,
confirmada contra el repositorio del profesor** (antes era un supuesto
propio sin validar).

| Registro | Offset | R/W | Descripción |
|---|---|---|---|
| `AUDIO1_DATA` | `0x00` | W | Muestra de audio para Pantalla 1 |
| `AUDIO2_DATA` | `0x04` | W | Muestra de audio para Pantalla 2 |
| `AUDIO3_DATA` | `0x08` | W | Muestra de audio para Pantalla 3 |
| `AUDIO4_DATA` | `0x0C` | W | Muestra de audio para Pantalla 4 |
| `AUDIO_STATUS` | `0x10` | R | bits 0-3 = `sample_req` de cada canal (listo para la siguiente muestra) |

## Integración en el SoC

`perip_i2s` recibe **`addr` como offset local** (ya restada la base
`0x470000`) — el decodificador central del SoC es responsable de:
1. Comparar la dirección del CPU contra la ventana `0x470000–0x47FFFF`.
2. Generar `cs = 1` solo cuando la dirección cae en esa ventana.
3. Conectar `addr = direccion_cpu - 0x470000` al puerto `addr` del
   módulo (mismo patrón que `perip_uart`, ver
   [`../grupo_B_uart/README.md`](../grupo_B_uart/README.md#integración-en-el-soc)).
4. Conectar las 12 salidas físicas (`bclk1..4`, `lrclk1..4`,
   `sdata1..4`) a los 4 DAC I2S externos, uno por pantalla.

## Simulación

```bash
cd rtl
make sim
```

Corre el testbench `perip_i2s_TB.v`: escribe una muestra SOLO en
`AUDIO1_DATA` y verifica que (1) el canal 1 arranca a generar `BCLK`, y
(2) los canales 2-4 permanecen inactivos — confirma el aislamiento
entre pantallas descrito arriba.

## API en C para el Grupo K

Ver [`firmware/i2s.h`](firmware/i2s.h) y
[`firmware/i2s.c`](firmware/i2s.c):

```c
void i2s_write1(int16_t muestra);  // Pantalla 1 — espera sample_req antes de escribir
void i2s_write2(int16_t muestra);  // Pantalla 2
void i2s_write3(int16_t muestra);  // Pantalla 3
void i2s_write4(int16_t muestra);  // Pantalla 4
void i2s_reproducir_efecto(void (*write_canal)(int16_t), const int16_t *muestras, int n);
```

Cada juego escribe muestras **solo a su canal correspondiente**. Los
efectos de sonido (salto, choque, punto) deben pre-generarse como
tablas de muestras en la flash (Grupo D), no calcularse en tiempo real
— más simple y predecible en tiempo de ejecución.

## Errores comunes a evitar
- Escribir muestras nuevas más rápido de lo que el hardware las
  consume (sin respetar `sample_req`/`AUDIO_STATUS`) — produce audio
  distorsionado o con "clicks". `i2s_write_canal` en `i2s.c` ya espera
  el bit correcto antes de escribir.
- Generar sonido en tiempo real con cálculos pesados dentro del bucle
  del juego — mejor usar tablas de muestras pre-generadas en la flash
  (Grupo D) para no afectar el framerate del juego.
- Usar la dirección ABSOLUTA (`0x470000 + offset`) dentro del propio
  módulo `perip_i2s.v` — el módulo solo debe conocer el offset; la
  base la maneja el decodificador central del SoC.

## Estado
- [x] Módulo diseñado (`perip_i2s.v`, 4× `i2s_tx`)
- [x] Testbench escrito (`perip_i2s_TB.v`)
- [ ] Módulo simulado y verificado (correr `make sim`)
- [ ] Módulo probado en hardware real (Colorlight 5A-75E)
- [x] Mapa de registros documentado (offsets arriba, base oficial confirmada)
