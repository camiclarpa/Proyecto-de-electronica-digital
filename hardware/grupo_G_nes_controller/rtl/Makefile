# Simulacion con Icarus Verilog + GTKWave (mismo flujo que usa el
# ejemplo del profesor en cores/blink/rtl/Makefile del template oficial).

sim:
	iverilog -o perip_nes_TB.vvp perip_nes_TB.v perip_nes.v
	vvp perip_nes_TB.vvp

ver: sim
	gtkwave perip_nes_TB.vcd perip_nes_TB.gtkw &

limpiar:
	rm -f perip_nes_TB.vvp perip_nes_TB.vcd

.PHONY: sim ver limpiar
