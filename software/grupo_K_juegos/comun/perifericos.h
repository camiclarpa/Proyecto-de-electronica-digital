// perifericos.h — UN SOLO LUGAR con todas las direcciones de hardware
// que el software necesita tocar. Cada direccion viene documentada en
// detalle en su carpeta hardware/grupo_*/README.md correspondiente --
// este archivo solo las junta para que ningun juego tenga que repetir
// "0x00060000" a mano por su cuenta.
//
// IMPORTANTE: estas direcciones son las PROPUESTAS documentadas en cada
// grupo de hardware, pendientes de validar contra el decodificador real
// (chip_select.v) del proyecto femtoriscv del curso. Actualizar aqui
// tan pronto se confirmen las direcciones reales.

#ifndef PERIFERICOS_H
#define PERIFERICOS_H

// ---- Grupo B: UART (hardware/grupo_B_uart) ----
#define UART_DATA   (*(volatile unsigned int*)0x00010000)
#define UART_STATUS (*(volatile unsigned int*)0x00010004)

// ---- Grupo C: SPI RAM / posible VRAM extendida (hardware/grupo_C_spiram) ----
#define SPIRAM_BASE   0x00020000
#define SPIRAM_STATUS (*(volatile unsigned int*)0x0002FFFC)

// ---- Grupo D: SPI Flash / assets de los juegos (hardware/grupo_D_spiflash) ----
#define FLASH_BASE   0x00030000
#define FLASH_STATUS (*(volatile unsigned int*)0x0003FFFC)

// ---- Grupo E: Teclado PS/2 (hardware/grupo_E_ps2_keyboard) ----
#define KBD_DATA   (*(volatile unsigned int*)0x00040000)
#define KBD_STATUS (*(volatile unsigned int*)0x00040004)

// ---- Grupo F: Mouse PS/2 (hardware/grupo_F_ps2_mouse) ----
#define MOUSE_STATUS (*(volatile unsigned int*)0x00050000)
#define MOUSE_DX     (*(volatile int*)0x00050004)
#define MOUSE_DY     (*(volatile int*)0x00050008)
#define MOUSE_VALID  (*(volatile unsigned int*)0x0005000C)

// ---- Grupo G: 8 controles NES (hardware/grupo_G_nes_controller) ----
// bit0=A, bit1=B, bit2=Select, bit3=Start, bit4=Up, bit5=Down, bit6=Left, bit7=Right
#define NES_P1 (*(volatile unsigned int*)0x00060000) // Pantalla 1, jugador A
#define NES_P2 (*(volatile unsigned int*)0x00060004) // Pantalla 1, jugador B
#define NES_P3 (*(volatile unsigned int*)0x00060008) // Pantalla 2, jugador A
#define NES_P4 (*(volatile unsigned int*)0x0006000C) // Pantalla 2, jugador B
#define NES_P5 (*(volatile unsigned int*)0x00060010) // Pantalla 3, jugador A
#define NES_P6 (*(volatile unsigned int*)0x00060014) // Pantalla 3, jugador B
#define NES_P7 (*(volatile unsigned int*)0x00060018) // Pantalla 4, jugador A
#define NES_P8 (*(volatile unsigned int*)0x0006001C) // Pantalla 4, jugador B

#define BOTON_A      0x01
#define BOTON_B      0x02
#define BOTON_SELECT 0x04
#define BOTON_START  0x08
#define BOTON_ARRIBA 0x10
#define BOTON_ABAJO  0x20
#define BOTON_IZQ    0x40
#define BOTON_DER    0x80

// ---- Grupo H: I2C (hardware/grupo_H_i2c) ----
#define I2C_ADDR   (*(volatile unsigned int*)0x00070000)
#define I2C_DATA   (*(volatile unsigned int*)0x00070004)
#define I2C_CTRL   (*(volatile unsigned int*)0x00070008)
#define I2C_STATUS (*(volatile unsigned int*)0x0007000C)

// ---- Grupo I: Audio I2S, 4 canales independientes (hardware/grupo_I_i2s) ----
#define AUDIO1_DATA  (*(volatile int*)0x00080000) // Pantalla 1
#define AUDIO2_DATA  (*(volatile int*)0x00080004) // Pantalla 2
#define AUDIO3_DATA  (*(volatile int*)0x00080008) // Pantalla 3
#define AUDIO4_DATA  (*(volatile int*)0x0008000C) // Pantalla 4
#define AUDIO_STATUS (*(volatile unsigned int*)0x00080010)

// ---- Grupo J: Framebuffers de las 4 pantallas (hardware/grupo_J_display) ----
// NOTA REAL PENDIENTE: el tamano real de cada framebuffer depende de la
// resolucion final que se decida (ver hardware/grupo_J_display/README.md,
// seccion sobre el problema real de tamano a 640x480 = ~460KB).
#define FB1_BASE 0x00090000 // Pantalla 1
#define FB2_BASE 0x00094000 // Pantalla 2
#define FB3_BASE 0x00098000 // Pantalla 3
#define FB4_BASE 0x0009C000 // Pantalla 4

#endif
