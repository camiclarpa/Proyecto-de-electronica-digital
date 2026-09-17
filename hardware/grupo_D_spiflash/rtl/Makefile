# Simulacion con Icarus Verilog + GTKWave (mismo flujo que usa el
# ejemplo del profesor en cores/blink/rtl/Makefile del template oficial).

sim:
	iverilog -o perip_spiflash_TB.vvp perip_spiflash_TB.v perip_spiflash.v
	vvp perip_spiflash_TB.vvp

ver: sim
	gtkwave perip_spiflash_TB.vcd perip_spiflash_TB.gtkw &

limpiar:
	rm -f perip_spiflash_TB.vvp perip_spiflash_TB.vcd

.PHONY: sim ver limpiar
