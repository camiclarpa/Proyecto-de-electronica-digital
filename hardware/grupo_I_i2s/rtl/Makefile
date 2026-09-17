# Simulacion con Icarus Verilog + GTKWave (mismo flujo que usa el
# ejemplo del profesor en cores/blink/rtl/Makefile del template oficial).

sim:
	iverilog -o perip_i2s_TB.vvp perip_i2s_TB.v perip_i2s.v
	vvp perip_i2s_TB.vvp

ver: sim
	gtkwave perip_i2s_TB.vcd perip_i2s_TB.gtkw &

limpiar:
	rm -f perip_i2s_TB.vvp perip_i2s_TB.vcd

.PHONY: sim ver limpiar
