#include "uart.h"

void uart_putc(char c) {
    while (UART_STATUS_REG & UART_STATUS_TX_BUSY) {}
    UART_DATA_REG = (uint32_t) c;
}

int uart_getc_available(void) {
    return UART_STATUS_REG & UART_STATUS_RX_VALID;
}

char uart_getc(void) {
    return (char) UART_DATA_REG;
}
