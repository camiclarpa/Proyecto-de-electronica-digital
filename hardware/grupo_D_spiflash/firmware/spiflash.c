#include "spiflash.h"

// Solo lectura: cada acceso dispara una transaccion SPI real hacia la
// flash de la tarjeta. Igual que spiram, el patron es "disparar y
// volver a leer despues de esperar busy==0", ya que el dato no esta
// disponible en el mismo ciclo del acceso.

uint32_t flash_read(uint32_t offset) {
    while (FLASH_STATUS_REG & FLASH_STATUS_BUSY) {}
    (void) FLASH_DATA(offset);              // dispara la transaccion de lectura
    while (FLASH_STATUS_REG & FLASH_STATUS_BUSY) {}
    return FLASH_DATA(offset);              // ahora si, dato ya capturado
}

// Copia n_palabras (words de 32 bits) desde la flash hacia RAM/BRAM.
// Siempre se usa UNA VEZ al iniciar cada juego -- nunca leer de flash
// dentro del bucle de dibujo de cada frame (es lenta comparada con BRAM).
void cargar_sprites(uint32_t offset_flash, uint32_t* destino_ram, int n_palabras) {
    int i;
    for (i = 0; i < n_palabras; i++)
        destino_ram[i] = flash_read(offset_flash + (uint32_t)(i * 4));
}
