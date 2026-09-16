# Grupo E — ps2_keyboard.v

Controlador de teclado PS/2 (configuración/depuración del sistema).

## Función en el proyecto

No es para jugar (eso lo hacen los 8 controles NES del Grupo G) — es
para que un adulto/desarrollador pueda configurar el sistema (ej.
escribir texto en un menú de administración, o depurar sin necesitar
los controles de juego).

## Protocolo real (PS/2)

Bus de 2 líneas en colector abierto: `PS2_CLK` y `PS2_DATA`. El
**teclado es quien genera el reloj** (10–16.7 kHz), no la FPGA. Cada
tecla se envía como una trama de 11 bits: 1 bit de start (siempre 0),
8 bits de datos (LSB primero), 1 bit de paridad impar, 1 bit de stop
(siempre 1). El controlador debe capturar cada bit en el flanco de
bajada de `PS2_CLK`.

- **Scancode Set 2** (el que usan los teclados PS/2 por defecto).
- Al **soltar** una tecla, el teclado manda primero el byte `0xF0`
  (break code) y luego el scancode de esa tecla.
- Teclas especiales (flechas, etc.) llevan un prefijo `0xE0` antes del
  scancode.

## Interfaz esperada (puertos del módulo)

```verilog
module ps2_keyboard (
    input  wire clk, rst,
    inout  wire ps2_clk,
    inout  wire ps2_data,
    output reg  [7:0] scancode,
    output reg          scancode_valid, // pulso: nuevo scancode disponible
    output reg           key_release     // 1 si el ultimo scancode fue precedido de 0xF0
);
```

## Mapa de memoria (PROPUESTO — validar contra el decodificador real `chip_select.v`)

| Dirección | Nombre | Lectura/Escritura | Descripción |
|---|---|---|---|
| `0x00040000` | KBD_DATA | R | bits[7:0] = scancode, bit8 = key_release |
| `0x00040004` | KBD_STATUS | R | bit0 = dato nuevo disponible (se limpia al leer KBD_DATA) |

## Requisitos desde el software (Grupo K)
- El decodificado de scancode → carácter/tecla (ej. traducir Set 2 a
  ASCII) se hace en **software**, no en el módulo Verilog — el módulo
  solo entrega el scancode crudo.
- Uso principal: menú de configuración/depuración, no gameplay.

## Estado
- [ ] Módulo diseñado
- [ ] Módulo simulado (testbench)
- [ ] Módulo probado en hardware real (Colorlight 5A-75E)
- [ ] Mapa de registros/memoria documentado (ver arriba)
