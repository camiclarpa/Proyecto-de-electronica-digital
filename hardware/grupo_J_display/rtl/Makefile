# Simulacion con Icarus Verilog + GTKWave (mismo flujo que usa el
# ejemplo del profesor en cores/blink/rtl/Makefile del template oficial).

sim:
	iverilog -o display_driver_TB.vvp display_driver_TB.v display_driver.v vga_timing.v framebuffer.v
	vvp display_driver_TB.vvp

ver: sim
	gtkwave display_driver_TB.vcd display_driver_TB.gtkw &

limpiar:
	rm -f display_driver_TB.vvp display_driver_TB.vcd

.PHONY: sim ver limpiar
