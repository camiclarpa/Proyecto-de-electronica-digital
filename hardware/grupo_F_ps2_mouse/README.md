# Grupo F — ps2_mouse.v

Controlador de mouse PS/2 (configuración/depuración del sistema).

## Función en el proyecto

Igual que el teclado PS/2 del Grupo E: es para configuración/depuración
del sistema, no para jugar (eso lo hacen los controles NES del Grupo G).
Podría usarse, por ejemplo, para un menú de administración con cursor.

## Protocolo real (PS/2, mismo bus físico que el teclado, distinto flujo)

Misma capa física que el teclado (`PS2_CLK`/`PS2_DATA`, colector
abierto, 11 bits por byte con paridad impar), pero el flujo es distinto:

1. Al conectarse, el mouse manda `0xAA 0x00` (self-test OK + device ID).
2. Para activar el modo de reporte continuo (*stream mode*), la FPGA
   debe mandar el comando `0xF4` al mouse (esto requiere que el
   controlador también sepa **transmitir** hacia el mouse, no solo
   recibir — el host baja `PS2_CLK` para pedir el turno de hablar).
3. Una vez activado, el mouse manda paquetes de **3 bytes** sin que se
   le pida, cada vez que se mueve o cambia un botón:
   - Byte 1: `[Y-overflow][X-overflow][Y-sign][X-sign][1][middle-btn][right-btn][left-btn]`
   - Byte 2: delta X (con signo, complemento a 2)
   - Byte 3: delta Y (con signo, complemento a 2)

## Interfaz esperada (puertos del módulo)

```verilog
module ps2_mouse (
    input  wire clk, rst,
    inout  wire ps2_clk,
    inout  wire ps2_data,
    output reg  [7:0] status_byte,
    output reg  signed [8:0] dx,
    output reg  signed [8:0] dy,
    output reg           packet_valid // pulso: nuevo paquete de 3 bytes completo
);
```

## Mapa de memoria (PROPUESTO — validar contra el decodificador real `chip_select.v`)

| Dirección | Nombre | Lectura/Escritura | Descripción |
|---|---|---|---|
| `0x00050000` | MOUSE_STATUS | R | byte de estado (botones + overflow) |
| `0x00050004` | MOUSE_DX | R | delta X con signo |
| `0x00050008` | MOUSE_DY | R | delta Y con signo |
| `0x0005000C` | MOUSE_VALID | R | bit0 = paquete nuevo disponible |

## Requisitos desde el software (Grupo K)
- Uso opcional/secundario — solo si el menú de administración lo
  necesita. No es parte del gameplay de los 4 juegos.

## Estado
- [ ] Módulo diseñado
- [ ] Módulo simulado (testbench)
- [ ] Módulo probado en hardware real (Colorlight 5A-75E)
- [ ] Mapa de registros/memoria documentado (ver arriba)
