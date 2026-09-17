#ifndef I2S_H
#define I2S_H

#include <stdint.h>

// Base real segun el mapa de memoria OFICIAL del curso (confirmado
// 2026-09-16, ver ../../../docs/mapa_memoria.md): ventana 0x470000-0x47FFFF.
#define I2S_BASE 0x470000u

#define AUDIO1_DATA_REG (*(volatile uint32_t*)(I2S_BASE + 0x00)) // Pantalla 1
#define AUDIO2_DATA_REG (*(volatile uint32_t*)(I2S_BASE + 0x04)) // Pantalla 2
#define AUDIO3_DATA_REG (*(volatile uint32_t*)(I2S_BASE + 0x08)) // Pantalla 3
#define AUDIO4_DATA_REG (*(volatile uint32_t*)(I2S_BASE + 0x0C)) // Pantalla 4
#define AUDIO_STATUS_REG (*(volatile uint32_t*)(I2S_BASE + 0x10))

#define AUDIO_STATUS_REQ1 0x1u // canal 1 listo para la siguiente muestra
#define AUDIO_STATUS_REQ2 0x2u // canal 2 listo para la siguiente muestra
#define AUDIO_STATUS_REQ3 0x4u // canal 3 listo para la siguiente muestra
#define AUDIO_STATUS_REQ4 0x8u // canal 4 listo para la siguiente muestra

// Escribe una muestra en el canal indicado, esperando a que el hardware
// la este pidiendo (AUDIO_STATUS) -- evita saturar el shift register y
// producir audio distorsionado ("clicks"), ver Errores comunes en el README.
void i2s_write_canal(volatile uint32_t *reg, uint32_t status_bit, int16_t muestra);

// Atajos por pantalla, para que cada juego solo toque SU canal.
void i2s_write1(int16_t muestra); // Pantalla 1
void i2s_write2(int16_t muestra); // Pantalla 2
void i2s_write3(int16_t muestra); // Pantalla 3
void i2s_write4(int16_t muestra); // Pantalla 4

// Reproduce un efecto pre-grabado (tabla de muestras cargada de la
// flash, Grupo D) por el canal indicado.
void i2s_reproducir_efecto(void (*write_canal)(int16_t), const int16_t *muestras, int n);

#endif
