#include "nes.h"

static volatile uint32_t * const NES_REGS[8] = {
    &NES_P1_REG, &NES_P2_REG, &NES_P3_REG, &NES_P4_REG,
    &NES_P5_REG, &NES_P6_REG, &NES_P7_REG, &NES_P8_REG
};

uint8_t nes_leer(int pantalla, int jugador) {
    int idx = (pantalla - 1) * 2 + jugador; // pantalla 1-4 -> 0..3, jugador 0=A,1=B
    return (uint8_t) (*NES_REGS[idx] & 0xFFu);
}

int nes_desconectado(uint8_t lectura) {
    return lectura == 0xFFu;
}
