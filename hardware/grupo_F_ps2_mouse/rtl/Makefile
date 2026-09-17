# Simulacion con Icarus Verilog + GTKWave (mismo flujo que usa el
# ejemplo del profesor en cores/blink/rtl/Makefile del template oficial).

sim:
	iverilog -o perip_ps2mouse_TB.vvp perip_ps2mouse_TB.v perip_ps2mouse.v
	vvp perip_ps2mouse_TB.vvp

ver: sim
	gtkwave perip_ps2mouse_TB.vcd perip_ps2mouse_TB.gtkw &

limpiar:
	rm -f perip_ps2mouse_TB.vvp perip_ps2mouse_TB.vcd

.PHONY: sim ver limpiar
