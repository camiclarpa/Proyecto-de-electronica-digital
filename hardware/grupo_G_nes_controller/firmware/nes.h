#ifndef NES_H
#define NES_H

#include <stdint.h>

// Base real segun el mapa de memoria OFICIAL del curso (confirmado
// 2026-09-16, ver ../../../docs/mapa_memoria.md): ventana 0x450000-0x45FFFF.
#define NES_BASE 0x450000u

#define NES_P1_REG (*(volatile uint32_t*)(NES_BASE + 0x00))
#define NES_P2_REG (*(volatile uint32_t*)(NES_BASE + 0x04))
#define NES_P3_REG (*(volatile uint32_t*)(NES_BASE + 0x08))
#define NES_P4_REG (*(volatile uint32_t*)(NES_BASE + 0x0C))
#define NES_P5_REG (*(volatile uint32_t*)(NES_BASE + 0x10))
#define NES_P6_REG (*(volatile uint32_t*)(NES_BASE + 0x14))
#define NES_P7_REG (*(volatile uint32_t*)(NES_BASE + 0x18))
#define NES_P8_REG (*(volatile uint32_t*)(NES_BASE + 0x1C))

#define NES_BOTON_A      0x01u
#define NES_BOTON_B      0x02u
#define NES_BOTON_SELECT 0x04u
#define NES_BOTON_START  0x08u
#define NES_BOTON_ARRIBA 0x10u
#define NES_BOTON_ABAJO  0x20u
#define NES_BOTON_IZQ    0x40u
#define NES_BOTON_DER    0x80u

// pantalla: 1-4. jugador: 0=A, 1=B. Devuelve los 8 bits de botones.
uint8_t nes_leer(int pantalla, int jugador);

// "todos los botones en 1" sostenido = control no conectado (pull-up
// de la linea DATA sin nada enchufado).
int nes_desconectado(uint8_t lectura);

#endif
