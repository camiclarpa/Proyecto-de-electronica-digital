# Simulacion con Icarus Verilog + GTKWave (mismo flujo que usa el
# ejemplo del profesor en cores/blink/rtl/Makefile del template oficial).

sim:
	iverilog -o perip_spiram_TB.vvp perip_spiram_TB.v perip_spiram.v
	vvp perip_spiram_TB.vvp

ver: sim
	gtkwave perip_spiram_TB.vcd perip_spiram_TB.gtkw &

limpiar:
	rm -f perip_spiram_TB.vvp perip_spiram_TB.vcd

.PHONY: sim ver limpiar
