# Diagramas — I2S (Audio)

## Trama I2S (BCLK / LRCLK / SDATA)

```
BCLK   ─┐┌┐┌┐┌┐┌┐┌┐┌┐┌┐┌─┐┌┐┌┐┌┐┌┐┌┐┌┐┌┐┌─
LRCLK  ──────────────────┘└──────────────  (0 = canal izq, 1 = canal der)
SDATA  ──[b15][b14]...[b1][b0]──[b15]...──  (MSB primero, cambia en flanco de bajada de BCLK)
```

- `BCLK` (bit clock): un pulso por cada bit de datos transmitido.
- `LRCLK`/`WS` (word select): indica a qué canal (izquierdo/derecho)
  pertenece el bit actual — en este proyecto se usa mono o estéreo
  simple (ver README).
- `SDATA`: los datos en sí, **MSB primero**, sincronizados al flanco de
  bajada de `BCLK` (ver `perip_i2s.v`, bloque `if (bclk) begin ... end`
  dentro de `i2s_tx`).

## Diagrama de bloques: 4 canales independientes

```mermaid
flowchart LR
    subgraph BUS["Bus del SoC (offset dentro de 0x470000-0x47FFFF)"]
        direction TB
        REG_IF["Interfaz de registros\n(cs, addr, rd, wr)"]
    end

    REG_IF -->|AUDIO1_DATA| CH1["i2s_tx canal 1"]
    REG_IF -->|AUDIO2_DATA| CH2["i2s_tx canal 2"]
    REG_IF -->|AUDIO3_DATA| CH3["i2s_tx canal 3"]
    REG_IF -->|AUDIO4_DATA| CH4["i2s_tx canal 4"]

    CH1 --> P1(("bclk1 / lrclk1 / sdata1\n→ DAC Pantalla 1"))
    CH2 --> P2(("bclk2 / lrclk2 / sdata2\n→ DAC Pantalla 2"))
    CH3 --> P3(("bclk3 / lrclk3 / sdata3\n→ DAC Pantalla 3"))
    CH4 --> P4(("bclk4 / lrclk4 / sdata4\n→ DAC Pantalla 4"))

    CH1 -.->|sample_req1| REG_IF
    CH2 -.->|sample_req2| REG_IF
    CH3 -.->|sample_req3| REG_IF
    CH4 -.->|sample_req4| REG_IF
```

Los 4 canales **no comparten estado**: cada `i2s_tx` tiene su propio
`shift_reg`, `bclk_count` y `bit_index`. Si el canal de una pantalla
falla o se satura, los otros 3 siguen sonando normal.

## Tabla de registros (ver también el README de esta carpeta)

| Registro | Offset | R/W | Descripción |
|---|---|---|---|
| `AUDIO1_DATA` | `0x00` | W | Muestra de audio para Pantalla 1 |
| `AUDIO2_DATA` | `0x04` | W | Muestra de audio para Pantalla 2 |
| `AUDIO3_DATA` | `0x08` | W | Muestra de audio para Pantalla 3 |
| `AUDIO4_DATA` | `0x0C` | W | Muestra de audio para Pantalla 4 |
| `AUDIO_STATUS` | `0x10` | R | bit0-3 = `sample_req` de cada canal (listo para la siguiente muestra) |
