# Simulacion con Icarus Verilog + GTKWave (mismo flujo que usa el
# ejemplo del profesor en cores/blink/rtl/Makefile del template oficial).

sim:
	iverilog -o perip_ps2kbd_TB.vvp perip_ps2kbd_TB.v perip_ps2kbd.v
	vvp perip_ps2kbd_TB.vvp

ver: sim
	gtkwave perip_ps2kbd_TB.vcd perip_ps2kbd_TB.gtkw &

limpiar:
	rm -f perip_ps2kbd_TB.vvp perip_ps2kbd_TB.vcd

.PHONY: sim ver limpiar
