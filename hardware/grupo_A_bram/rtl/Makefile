sim:
	iverilog -o bram_TB.vvp bram_TB.v bram.v
	vvp bram_TB.vvp

ver: sim
	gtkwave bram_TB.vcd bram_TB.gtkw &

limpiar:
	rm -f bram_TB.vvp bram_TB.vcd

.PHONY: sim ver limpiar
