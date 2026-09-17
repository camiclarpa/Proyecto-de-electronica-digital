#ifndef SPIFLASH_H
#define SPIFLASH_H

#include <stdint.h>

// Base real segun el mapa de memoria OFICIAL del curso (confirmado
// 2026-09-16, ver ../../../docs/mapa_memoria.md): ventana 0x420000-0x42FFFF (64KB).
#define FLASH_BASE 0x00420000u

// Ventana de datos, solo lectura: offset 0x0000 en adelante (word-aligned).
#define FLASH_DATA(offset)  (*(volatile uint32_t*)(FLASH_BASE + (offset)))
// Ultimo word de la ventana de 64KB.
#define FLASH_STATUS_REG    (*(volatile uint32_t*)(FLASH_BASE + 0xFFFCu))

#define FLASH_STATUS_BUSY 0x1u

uint32_t flash_read(uint32_t offset);
void     cargar_sprites(uint32_t offset_flash, uint32_t* destino_ram, int n_palabras);

#endif
