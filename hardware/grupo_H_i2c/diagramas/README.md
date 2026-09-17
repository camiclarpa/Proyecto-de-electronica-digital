# Diagramas — I2C

## Trama de una transferencia de 1 byte (START, ADDR+RW, ACK, DATA, ACK, STOP)

```mermaid
sequenceDiagram
    participant M as perip_i2c (maestro)
    participant S as Esclavo I2C
    M->>S: START (SDA baja con SCL en alto)
    M->>S: 7 bits de direccion + 1 bit R/W
    S-->>M: ACK (SDA baja durante el 9no pulso de SCL)
    alt Escritura (RW=0)
        M->>S: 8 bits de datos
        S-->>M: ACK
    else Lectura (RW=1)
        S->>M: 8 bits de datos
        M-->>S: NACK (transferencia de 1 solo byte)
    end
    M->>S: STOP (SDA sube con SCL en alto)
```

- Cada bit se establece con `SCL` en bajo y se muestrea con `SCL` en
  alto — nunca al revés (si `SDA` cambia con `SCL` en alto, eso es una
  condición START o STOP, no un bit de datos).
- **Clock stretching**: tras liberar `SCL` para que suba, el maestro
  vuelve a leer la línea antes de darla por alta — si el esclavo la
  retiene en 0 para pedir más tiempo, el maestro simplemente espera
  (ver fase `PH1` en `perip_i2c.v`).

## Diagrama de bloques interno

```mermaid
flowchart LR
    subgraph BUS["Bus del SoC (offset dentro de 0x460000-0x46FFFF)"]
        direction TB
        REG_IF["Interfaz de registros\n(cs, addr, rd, wr)"]
    end

    REG_IF --> FSM["FSM maestro I2C\n(START / BYTE / ACK / STOP)"]
    FSM <-- "scl (colector abierto)" --> SCLPIN(("SCL"))
    FSM <-- "sda (colector abierto)" --> SDAPIN(("SDA"))
    FSM --> REG_IF
```

## Tabla de registros (ver también el README de esta carpeta)

| Registro | Offset | R/W | Bit | Significado |
|---|---|---|---|---|
| `I2C_ADDR` | `0x00` | W | `[6:0]` | Dirección del esclavo (7 bits) |
| `I2C_DATA` | `0x04` | R/W | `[7:0]` | Escribir: byte a mandar. Leer: último byte recibido |
| `I2C_CTRL` | `0x08` | W | bit0 | `start` — pulso: inicia la transacción |
| `I2C_CTRL` | `0x08` | W | bit1 | `rw` — 0=escritura, 1=lectura |
| `I2C_STATUS` | `0x0C` | R | bit0 | `busy` — 1 mientras hay una transacción en curso |
| `I2C_STATUS` | `0x0C` | R | bit1 | `ack_error` — 1 si el esclavo no respondió ACK |
