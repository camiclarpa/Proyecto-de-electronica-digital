#ifndef PS2_MOUSE_H
#define PS2_MOUSE_H

#include <stdint.h>

// Base real segun el mapa de memoria OFICIAL del curso (confirmado
// 2026-09-16, ver ../../../docs/mapa_memoria.md): ventana 0x440000-0x44FFFF.
#define MOUSE_BASE 0x00440000u

#define MOUSE_STATUS_REG (*(volatile uint32_t*)(MOUSE_BASE + 0x00))
#define MOUSE_DX_REG      (*(volatile int32_t*) (MOUSE_BASE + 0x04))
#define MOUSE_DY_REG      (*(volatile int32_t*) (MOUSE_BASE + 0x08))
#define MOUSE_VALID_REG  (*(volatile uint32_t*)(MOUSE_BASE + 0x0C))

#define MOUSE_STATUS_LEFT_BTN   0x01u
#define MOUSE_STATUS_RIGHT_BTN  0x02u
#define MOUSE_STATUS_MIDDLE_BTN 0x04u

int      mouse_dato_nuevo(void);
uint8_t  mouse_leer_status(void);
int32_t  mouse_leer_dx(void);
int32_t  mouse_leer_dy(void);

#endif
