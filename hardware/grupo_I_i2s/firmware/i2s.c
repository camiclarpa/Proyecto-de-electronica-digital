#include "i2s.h"

void i2s_write_canal(volatile uint32_t *reg, uint32_t status_bit, int16_t muestra) {
    while (!(AUDIO_STATUS_REG & status_bit)) {} // espera a que el canal pida la siguiente muestra
    *reg = (uint32_t)(uint16_t) muestra;
}

void i2s_write1(int16_t muestra) { i2s_write_canal(&AUDIO1_DATA_REG, AUDIO_STATUS_REQ1, muestra); }
void i2s_write2(int16_t muestra) { i2s_write_canal(&AUDIO2_DATA_REG, AUDIO_STATUS_REQ2, muestra); }
void i2s_write3(int16_t muestra) { i2s_write_canal(&AUDIO3_DATA_REG, AUDIO_STATUS_REQ3, muestra); }
void i2s_write4(int16_t muestra) { i2s_write_canal(&AUDIO4_DATA_REG, AUDIO_STATUS_REQ4, muestra); }

void i2s_reproducir_efecto(void (*write_canal)(int16_t), const int16_t *muestras, int n) {
    for (int i = 0; i < n; i++) {
        write_canal(muestras[i]);
    }
}
