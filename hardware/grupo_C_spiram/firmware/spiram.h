#ifndef SPIRAM_H
#define SPIRAM_H

#include <stdint.h>

// Base real segun el mapa de memoria OFICIAL del curso (confirmado
// 2026-09-16, ver ../../../docs/mapa_memoria.md): ventana 0x410000-0x41FFFF (64KB).
#define SPIRAM_BASE 0x00410000u

// Ventana de datos pass-through: offset 0x0000 en adelante (word-aligned).
#define SPIRAM_DATA(offset)  (*(volatile uint32_t*)(SPIRAM_BASE + (offset)))
// Ultimo word de la ventana de 64KB.
#define SPIRAM_STATUS_REG    (*(volatile uint32_t*)(SPIRAM_BASE + 0xFFFCu))

#define SPIRAM_STATUS_BUSY 0x1u

uint32_t spiram_read(uint32_t offset);
void     spiram_write(uint32_t offset, uint32_t value);

#endif
