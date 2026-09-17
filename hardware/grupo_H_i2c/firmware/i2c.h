#ifndef I2C_H
#define I2C_H

#include <stdint.h>

// Base real segun el mapa de memoria OFICIAL del curso (confirmado
// 2026-09-16, ver ../../../docs/mapa_memoria.md): ventana 0x460000-0x46FFFF.
#define I2C_BASE 0x460000u

#define I2C_ADDR_REG   (*(volatile uint32_t*)(I2C_BASE + 0x00))
#define I2C_DATA_REG   (*(volatile uint32_t*)(I2C_BASE + 0x04))
#define I2C_CTRL_REG   (*(volatile uint32_t*)(I2C_BASE + 0x08))
#define I2C_STATUS_REG (*(volatile uint32_t*)(I2C_BASE + 0x0C))

#define I2C_CTRL_START 0x1u
#define I2C_CTRL_RW    0x2u   // 0=escritura, 1=lectura (se combina con START)

#define I2C_STATUS_BUSY      0x1u
#define I2C_STATUS_ACK_ERROR 0x2u

// Devuelven 0 si hubo ACK del esclavo, distinto de 0 si no respondio.
int i2c_escribir(uint8_t addr7, uint8_t dato);
int i2c_leer(uint8_t addr7, uint8_t *dato_leido);

#endif
