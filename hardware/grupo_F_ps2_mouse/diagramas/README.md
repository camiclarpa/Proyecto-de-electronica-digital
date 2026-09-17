# Diagramas — Mouse PS/2

## Trama de un byte (11 bits, protocolo PS/2 — idéntica a nivel de bits a la del teclado)

```
reposo  start  d0  d1  d2  d3  d4  d5  d6  d7  parity  stop  reposo
  1  ──▁──┤ 0 │ ¹  ¹  ¹  ¹  ¹  ¹  ¹  ¹ │  P   │ 1 │──────  1
          └───┴──┴──┴──┴──┴──┴──┴──┴──┴──────┴───┘
          cada bit se muestrea en el flanco de BAJADA de PS2_CLK
```

Mismo receptor de bytes de 11 bits que usa el teclado (Grupo E) — ver
también [`../../grupo_E_ps2_keyboard/diagramas/README.md`](../../grupo_E_ps2_keyboard/diagramas/README.md).

## Paquete de reporte del mouse (3 bytes)

```
Byte 1 (status):  [Y-overflow][X-overflow][Y-sign][X-sign][1][middle-btn][right-btn][left-btn]
Byte 2 (dx):       delta X, complemento a 2 (bit de signo va en status[4])
Byte 3 (dy):       delta Y, complemento a 2 (bit de signo va en status[5])
```

```mermaid
sequenceDiagram
    participant MOU as Mouse (maestro del reloj)
    participant FPGA as perip_ps2mouse

    MOU->>FPGA: byte 1/3 -> status_byte (botones + overflow + signos)
    MOU->>FPGA: byte 2/3 -> dx = {status[4], byte}
    MOU->>FPGA: byte 3/3 -> dy = {status[5], byte}
    FPGA-->>FPGA: MOUSE_VALID = 1 (paquete completo)
    Note over MOU,FPGA: antes de esto, la FPGA debe mandar 0xF4\npara activar el modo streaming (PENDIENTE, ver README.md)
```

## Diagrama de bloques interno

```mermaid
flowchart LR
    subgraph BUS["Bus del SoC (offset dentro de 0x440000-0x44FFFF)"]
        direction TB
        REG_IF["Interfaz de registros\n(cs, addr, rd, wr)"]
    end

    PS2CLK(("ps2_clk")) --> SYNC["Sincronizador\n2 flip-flops"]
    PS2DATA(("ps2_data")) --> SYNC
    SYNC --> RXFSM["Receptor de 11 bits\n(igual al del teclado)"]
    RXFSM --> PKT["Acumulador de paquete\n(3 bytes -> status/dx/dy)"]
    PKT --> REG_IF
```

## Tabla de registros (ver también el README de esta carpeta)

| Registro | Offset | R/W | Significado |
|---|---|---|---|
| `MOUSE_STATUS` | `0x00` | R | byte de estado crudo: bit0=left, bit1=right, bit2=middle, bit3=1 fijo, bit4=X-sign, bit5=Y-sign, bit6/7=overflow |
| `MOUSE_DX` | `0x04` | R | delta X con signo (extendido a 32 bits) |
| `MOUSE_DY` | `0x08` | R | delta Y con signo (extendido a 32 bits) |
| `MOUSE_VALID` | `0x0C` | R | bit0 = paquete nuevo disponible (se limpia al leer) |
