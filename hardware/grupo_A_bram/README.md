# Grupo A — `bram`

Controlador de BRAM interna (memoria de trabajo del CPU RV32I).

> **Dirección actualizada 2026-09-16**: se confirmó contra el mapa de
> memoria oficial del curso (antes era un supuesto propio sin
> validar). Detalle en
> [`../../docs/decisiones_cerradas.md`](../../docs/decisiones_cerradas.md).

## Función en el proyecto

Es la memoria de trabajo principal del CPU: ahí vive el programa
compilado (el software del Grupo K) mientras se ejecuta, y las
variables/pila de cada tarea de juego. Toda lectura/escritura del CPU
que no vaya dirigida a un periférico específico pasa por aquí.

## Estructura de esta carpeta

```
grupo_A_bram/
├── README.md              (este archivo)
├── diagramas/README.md    — por qué 4 bancos de 8 bits, ventana vs. BRAM física real
├── rtl/
│   ├── Makefile
│   ├── bram.v               — módulo real (no sigue el patrón perip_ / CSR, ver más abajo)
│   └── bram_TB.v             — testbench (palabra completa + escritura parcial por byte)
└── firmware/README.md      — por qué este módulo no tiene driver C
```

## Por qué no se llama `perip_bram` ni sigue el patrón CSR

A diferencia de los demás módulos de `hardware/`, la BRAM no es un
periférico con registros de control — es memoria de programa normal.
Se accede con `LW`/`SW`/`LB`/`SB` directo, como cualquier arreglo de
C, sin necesitar un protocolo `cs`/`rd`/`wr` de un solo registro a la
vez. Por eso su interfaz (ver `rtl/bram.v`) es distinta a la del resto.

## Interfaz del módulo

```verilog
module bram (
    input  wire        clk,
    input  wire [19:0] addr,        // direccion de PALABRA (32 bits)
    input  wire [31:0] data_in,
    output reg  [31:0] data_out,
    input  wire        write_enable,
    input  wire [3:0]  byte_enable // escritura parcial (SB/SH del RISC-V)
);
```

- Acceso síncrono (1 ciclo de latencia), como cualquier BRAM de FPGA (Lattice ECP5, bloques de 18 Kbit).
- Debe soportar escritura por byte (`byte_enable`) porque el compilador de C para RV32I genera instrucciones `SB`/`SH` además de `SW`.

## Ventana de direcciones

| Rango | Tamaño de ventana | R/W | Descripción |
|---|---|---|---|
| `0x000000`–`0x3FFFFF` | 4 MB (dirección), NO BRAM física real | R/W | Memoria de trabajo del CPU (código + datos) |

Ver la nota importante sobre ventana de direcciones vs. BRAM física
real de la FPGA en
[`diagramas/README.md`](diagramas/README.md#ventana-de-direcciones-vs-bram-física-real-de-la-fpga)
— 4 MB es el tamaño del espacio de direcciones reservado, no el
tamaño real de BRAM disponible en el chip.

## Requisitos desde el software (Grupo K)

- Tamaño mínimo: suficiente para el código de los 4 juegos + pila +
  variables globales de estado (medir con el `.elf` real una vez
  compile el primer juego, no adivinar el tamaño de antemano).
- Debe poder inicializarse con el contenido del programa al configurar
  la FPGA (memoria inicializada desde el bitstream, como ya hace el
  ejemplo `femtorv32` del curso vía `init_dpram.ini`).

## Simulación

```bash
cd rtl
make sim
```

## Errores comunes a evitar
- Olvidar el `byte_enable` y solo soportar `SW` de 32 bits — el
  compilador de C SÍ genera `SB`/`SH` para variables `char`/`short`,
  y sin esto el programa falla de forma silenciosa y difícil de
  depurar.
- No inicializar la memoria con el programa real al sintetizar (sin
  esto, el CPU arranca ejecutando basura).
- Asumir que caben 4MB reales de BRAM en la FPGA — ver la nota de
  arriba.

## Estado
- [x] Módulo diseñado
- [x] Testbench escrito (`bram_TB.v`)
- [ ] Módulo simulado y verificado (correr `make sim`)
- [ ] Módulo probado en hardware real (Colorlight 5A-75E)
- [x] Ventana de direcciones documentada (oficial, confirmada)
