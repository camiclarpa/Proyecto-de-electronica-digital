#ifndef PS2_KEYBOARD_H
#define PS2_KEYBOARD_H

#include <stdint.h>

// Base real segun el mapa de memoria OFICIAL del curso (confirmado
// 2026-09-16, ver ../../../docs/mapa_memoria.md): ventana 0x430000-0x43FFFF.
#define KBD_BASE 0x00430000u

#define KBD_DATA_REG   (*(volatile uint32_t*)(KBD_BASE + 0x00))
#define KBD_STATUS_REG (*(volatile uint32_t*)(KBD_BASE + 0x04))

#define KBD_STATUS_VALID      0x1u
#define KBD_DATA_RELEASE_BIT  0x100u // bit8 de KBD_DATA = key_release

int           kbd_tecla_disponible(void);
unsigned char kbd_leer_scancode(void);
int           kbd_fue_soltada(void);

#endif
