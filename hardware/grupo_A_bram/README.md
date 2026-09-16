# Grupo A — bram.v

Controlador de BRAM interna (memoria de trabajo del CPU RV32I).

## Función en el proyecto

Es la memoria de trabajo principal del CPU: ahí vive el programa
compilado (el software del Grupo K) mientras se ejecuta, y las
variables/pila de cada tarea de juego. Toda lectura/escritura del CPU
que no vaya dirigida a un periférico específico pasa por aquí.

## Interfaz esperada (puertos del módulo)

```verilog
module bram (
    input  wire        clk,
    input  wire [15:0] addr,        // direccion de palabra
    input  wire [31:0] data_in,
    output reg  [31:0] data_out,
    input  wire         write_enable,
    input  wire  [3:0]  byte_enable // escritura parcial (SB/SH del RISC-V)
);
```

- Acceso síncrono (1 ciclo de latencia), como cualquier BRAM de FPGA (Lattice ECP5, bloques de 18 Kbit).
- Debe soportar escritura por byte (`byte_enable`) porque el compilador de C para RV32I genera instrucciones `SB`/`SH` además de `SW`.

## Requisitos desde el software (Grupo K)

- Tamaño mínimo: suficiente para el código de los 4 juegos + pila +
  variables globales de estado (medir con el `.elf` real una vez
  compile el primer juego, no adivinar el tamaño de antemano).
- Debe poder inicializarse con el contenido del programa al configurar
  la FPGA (memoria inicializada desde el bitstream, como ya hace el
  ejemplo `femtoriscv` del curso vía `init_dpram.ini`).

## Mapa de memoria (PROPUESTO — validar contra el decodificador real `chip_select.v` del proyecto femtoriscv del curso)

| Dirección | Nombre | Lectura/Escritura | Descripción |
|---|---|---|---|
| `0x00000000` – `0x0000FFFF` | BRAM | R/W | Memoria de trabajo del CPU (código + datos) |

## Estado
- [ ] Módulo diseñado
- [ ] Módulo simulado (testbench)
- [ ] Módulo probado en hardware real (Colorlight 5A-75E)
- [ ] Mapa de registros/memoria documentado (ver arriba)
