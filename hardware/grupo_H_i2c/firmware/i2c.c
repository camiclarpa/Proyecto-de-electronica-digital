#include "i2c.h"

static void i2c_esperar_libre(void) {
    while (I2C_STATUS_REG & I2C_STATUS_BUSY) {}
}

int i2c_escribir(uint8_t addr7, uint8_t dato) {
    i2c_esperar_libre();
    I2C_ADDR_REG = addr7;
    I2C_DATA_REG = dato;
    I2C_CTRL_REG = I2C_CTRL_START; // rw=0 (escritura)
    i2c_esperar_libre();
    return (I2C_STATUS_REG & I2C_STATUS_ACK_ERROR) ? -1 : 0;
}

int i2c_leer(uint8_t addr7, uint8_t *dato_leido) {
    i2c_esperar_libre();
    I2C_ADDR_REG = addr7;
    I2C_CTRL_REG = I2C_CTRL_START | I2C_CTRL_RW;
    i2c_esperar_libre();
    if (I2C_STATUS_REG & I2C_STATUS_ACK_ERROR) return -1;
    *dato_leido = (uint8_t) I2C_DATA_REG;
    return 0;
}
