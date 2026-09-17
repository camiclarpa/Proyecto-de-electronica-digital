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

## Esqueleto de implementación (punto de partida real, no pseudocódigo)

```verilog
module bram (
    input  wire        clk,
    input  wire [15:0] addr,
    input  wire [31:0] data_in,
    output reg  [31:0] data_out,
    input  wire        write_enable,
    input  wire [3:0]  byte_enable
);
    reg [7:0] mem0 [0:16383];
    reg [7:0] mem1 [0:16383];
    reg [7:0] mem2 [0:16383];
    reg [7:0] mem3 [0:16383];

    always @(posedge clk) begin
        if (write_enable) begin
            if (byte_enable[0]) mem0[addr] <= data_in[7:0];
            if (byte_enable[1]) mem1[addr] <= data_in[15:8];
            if (byte_enable[2]) mem2[addr] <= data_in[23:16];
            if (byte_enable[3]) mem3[addr] <= data_in[31:24];
        end
        data_out <= {mem3[addr], mem2[addr], mem1[addr], mem0[addr]};
    end
endmodule
```

Nota: partir la memoria en 4 bancos de 8 bits (uno por byte) es lo que
permite escribir por byte sin leer-modificar-escribir la palabra
completa — así funciona de verdad el `SB`/`SH` del RISC-V.

## API en C para el Grupo K

```c
// bram.h — memoria de trabajo, acceso normal de C (arreglos, punteros)
// No requiere funciones especiales: el compilador de GCC para RV32I ya
// genera LW/SW/LB/SB directo sobre estas direcciones porque es memoria
// mapeada de forma transparente, a diferencia de los periféricos.
```

## Errores comunes a evitar
- Olvidar el `byte_enable` y solo soportar `SW` de 32 bits — el
  compilador de C SÍ genera `SB`/`SH` para variables `char`/`short`,
  y sin esto el programa falla de forma silenciosa y difícil de
  depurar.
- No inicializar la memoria con el programa real al sintetizar (sin
  esto, el CPU arranca ejecutando basura).

## Estado
- [ ] Módulo diseñado
- [ ] Módulo simulado (testbench)
- [ ] Módulo probado en hardware real (Colorlight 5A-75E)
- [ ] Mapa de registros/memoria documentado (ver arriba)
