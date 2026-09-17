# Makefile — estructura de compilacion, siguiendo el mismo flujo que
# usa el ejemplo femtoriscv del curso (ver
# https://github.com/johnnycubides/digital-electronic-1-101/tree/main/fpga-example/colorlight-5a-75e/femtoriscv):
# compilar en C para RV32I con el toolchain de GCC, generar un .hex que
# se carga a la BRAM del SoC.
#
# ESTO ES ESTRUCTURA: los archivos .c que aqui se referencian todavia
# no existen (main.c, pong.c, etc.) -- este Makefile documenta COMO se
# van a compilar y enlazar una vez existan, no los compila todavia.

CC      = riscv32-unknown-elf-gcc
OBJCOPY = riscv32-unknown-elf-objcopy
CFLAGS  = -march=rv32i -mabi=ilp32 -O2 -ffreestanding -nostdlib -I.

# Cada juego aporta su propio .c; main.c decide cual InterfazJuego usar
# segun la pantalla (ver README.md de esta carpeta, seccion de
# multiplexado round-robin vs tareas).
FUENTES = main.c \
          ../pong/pong.c \
          ../space_invaders/space_invaders.c \
          ../snake/snake.c \
          ../carrito/carrito.c

TARGET = juegos.elf

todo: $(TARGET)

$(TARGET): $(FUENTES)
	$(CC) $(CFLAGS) -o $(TARGET) $(FUENTES)

hex: $(TARGET)
	$(OBJCOPY) -O ihex $(TARGET) juegos.hex

limpiar:
	rm -f $(TARGET) juegos.hex

.PHONY: todo hex limpiar
