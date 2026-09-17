#ifndef UART_H
#define UART_H

#include <stdint.h>

// Base real segun el mapa de memoria OFICIAL del curso (confirmado
// 2026-09-16, ver ../../../docs/mapa_memoria.md): ventana 0x400000-0x40FFFF.
#define UART_BASE 0x400000u

#define UART_DATA_REG   (*(volatile uint32_t*)(UART_BASE + 0x00))
#define UART_STATUS_REG (*(volatile uint32_t*)(UART_BASE + 0x04))

#define UART_STATUS_TX_BUSY  0x1u
#define UART_STATUS_RX_VALID 0x2u

void uart_putc(char c);
int  uart_getc_available(void);
char uart_getc(void);

#endif
