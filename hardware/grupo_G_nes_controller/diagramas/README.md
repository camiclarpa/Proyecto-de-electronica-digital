# Diagramas — NES Controller

## Secuencia Latch/Clock (lectura de 1 control, CD4021)

```mermaid
sequenceDiagram
    participant SoC as perip_nes (FPGA)
    participant CD as CD4021 (control NES)
    SoC->>CD: LATCH = 1 (~12us)
    Note over CD: Carga paralela de los 8 botones
    SoC->>CD: LATCH = 0
    CD-->>SoC: DATA = bit0 (A)
    loop 7 pulsos mas de CLOCK (~12us periodo)
        SoC->>CD: CLOCK = 1 -> 0
        CD-->>SoC: DATA = siguiente bit
    end
    Note over SoC: Orden real: A, B, Select, Start, Up, Down, Left, Right
```

- `LATCH` y `CLOCK` son compartidas por los 8 controles (se leen los 8 en
  paralelo, al mismo tiempo); `DATA` es una línea individual por control.
- Un control desconectado lee todo en 1 (pull-up de `DATA` sin nada
  enchufado) — ver "Errores comunes" en el README de esta carpeta.

## Diagrama de bloques (8 controles, líneas compartidas)

```mermaid
flowchart LR
    subgraph BUS["Bus del SoC (offset dentro de 0x450000-0x45FFFF)"]
        direction TB
        REG_IF["Interfaz de registros\n(cs, addr, rd)"]
    end

    REG_IF --> FSM["FSM Latch/Clock\n(perip_nes)"]
    FSM -- latch, clock_out --> C1["Control 1\n(CD4021)"]
    FSM -- latch, clock_out --> C2["Control 2"]
    FSM -. latch, clock_out .-> C8["... Control 8"]
    C1 -- data[0] --> FSM
    C2 -- data[1] --> FSM
    C8 -. data[7] .-> FSM
    FSM --> REG_IF
```

## Tabla de registros (ver también el README de esta carpeta)

| Registro | Offset | R/W | Descripción |
|---|---|---|---|
| `NES_P1` | `0x00` | R | Pantalla 1, jugador A |
| `NES_P2` | `0x04` | R | Pantalla 1, jugador B |
| `NES_P3` | `0x08` | R | Pantalla 2, jugador A |
| `NES_P4` | `0x0C` | R | Pantalla 2, jugador B |
| `NES_P5` | `0x10` | R | Pantalla 3, jugador A |
| `NES_P6` | `0x14` | R | Pantalla 3, jugador B |
| `NES_P7` | `0x18` | R | Pantalla 4, jugador A |
| `NES_P8` | `0x1C` | R | Pantalla 4, jugador B |

Bits de cada registro (igual para los 8): `bit0`=A, `bit1`=B,
`bit2`=Select, `bit3`=Start, `bit4`=Up, `bit5`=Down, `bit6`=Left,
`bit7`=Right.
