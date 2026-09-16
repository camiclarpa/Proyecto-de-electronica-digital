# Grupo I — i2s_tx.v

Transmisor de audio I2S (4 salidas de sonido independientes).

## Función en el proyecto

Genera el sonido de cada uno de los 4 juegos, de forma independiente
(el sonido de Pong en la Pantalla 1 no debe mezclarse con el de Snake
en la Pantalla 3).

## Cómo resolver "4 sonidos al mismo tiempo" (pregunta abierta del README principal)

La solución real más simple: **4 instancias independientes** del mismo
módulo `i2s_tx.v` (una por pantalla/juego), cada una con su propio DAC
externo I2S. No hay que mezclar audio en software — cada juego solo le
habla a SU instancia, sin saber que existen las otras 3. Esto es
consistente con el requisito de aislamiento de fallos: si el audio de
una pantalla falla, las otras 3 siguen sonando normal.

(Alternativa si solo hay 1 DAC físico disponible: mezclar las 4 señales
en software antes de un único I2S — más complejo y NO es lo que pide el
requisito original de "4 salidas de sonido". Usar 4 instancias salvo que
el hardware real disponible no lo permita.)

## Protocolo real (I2S)

3 líneas: `BCLK` (bit clock), `LRCLK`/`WS` (word select: 0=canal
izquierdo, 1=canal derecho), `SDATA` (datos, MSB primero). Formato
recomendado para este proyecto: **16 bits, mono o estéreo simple,
8–16 kHz de frecuencia de muestreo** (más que suficiente para efectos
de sonido de videojuego retro — no hace falta calidad de música, y una
frecuencia baja simplifica mucho el diseño y el tamaño de los assets de
audio en la flash).

## Interfaz esperada (puertos del módulo, por cada instancia)

```verilog
module i2s_tx #(parameter SAMPLE_RATE = 8000, parameter BITS = 16) (
    input  wire clk, rst,
    output wire bclk, lrclk, sdata,
    input  wire signed [BITS-1:0] sample_in,
    input  wire                    sample_write, // pulso: nueva muestra lista
    output wire                    sample_req     // pulso: el modulo pide la siguiente muestra
);
```

## Mapa de memoria (PROPUESTO — validar contra el decodificador real `chip_select.v`)

| Dirección | Nombre | Lectura/Escritura | Descripción |
|---|---|---|---|
| `0x00080000` | AUDIO1_DATA | W | Muestra de audio para Pantalla 1 |
| `0x00080004` | AUDIO2_DATA | W | Muestra de audio para Pantalla 2 |
| `0x00080008` | AUDIO3_DATA | W | Muestra de audio para Pantalla 3 |
| `0x0008000C` | AUDIO4_DATA | W | Muestra de audio para Pantalla 4 |
| `0x00080010` | AUDIO_STATUS | R | bits 0-3 = sample_req de cada canal (listo para siguiente muestra) |

## Requisitos desde el software (Grupo K)
- Cada juego escribe muestras SOLO a su canal correspondiente.
- Los efectos de sonido (salto, choque, punto) deben pre-generarse como
  tablas de muestras en la flash (Grupo D), no calcularse en tiempo
  real — más simple y predecible en tiempo de ejecución.

## Estado
- [ ] Módulo diseñado
- [ ] Módulo simulado (testbench)
- [ ] Módulo probado en hardware real (Colorlight 5A-75E)
- [ ] Mapa de registros/memoria documentado (ver arriba)
