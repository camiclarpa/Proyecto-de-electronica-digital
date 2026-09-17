# Simulacion con Icarus Verilog + GTKWave (mismo flujo que usa el
# ejemplo del profesor en cores/blink/rtl/Makefile del template oficial).

sim:
	iverilog -o perip_uart_TB.vvp perip_uart_TB.v perip_uart.v
	vvp perip_uart_TB.vvp

ver: sim
	gtkwave perip_uart_TB.vcd perip_uart_TB.gtkw &

limpiar:
	rm -f perip_uart_TB.vvp perip_uart_TB.vcd

.PHONY: sim ver limpiar
