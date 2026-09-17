// perifericos.h — UN SOLO LUGAR con todas las direcciones de hardware
// que el software necesita tocar. Cada direccion viene documentada en
// detalle en su carpeta hardware/grupo_*/README.md correspondiente --
// este archivo solo las junta para que ningun juego tenga que repetir
// una direccion a mano por su cuenta.
//
// Direcciones OFICIALES, confirmadas 2026-09-16 contra el mapa de
// memoria real del curso (antes eran un supuesto propio sin validar
// contra ningun decodificador real). Ver docs/mapa_memoria.md y
// docs/decisiones_cerradas.md para el detalle y la fuente.

#ifndef PERIFERICOS_H
#define PERIFERICOS_H

// ---- Grupo A: BRAM (hardware/grupo_A_bram) — 0x000000-0x3FFFFF ----
// No tiene registros de control: es memoria de programa normal,
// accedida por el compilador de C de forma transparente (LW/SW/LB/SB).

// ---- Grupo B: UART (hardware/grupo_B_uart) — 0x400000-0x40FFFF ----
#define UART_DATA   (*(volatile unsigned int*)0x00400000)
#define UART_STATUS (*(volatile unsigned int*)0x00400004)

// ---- Grupo C: SPI RAM / posible VRAM extendida (hardware/grupo_C_spiram) — 0x410000-0x41FFFF ----
#define SPIRAM_BASE   0x00410000
#define SPIRAM_STATUS (*(volatile unsigned int*)0x0041FFFC)

// ---- Grupo D: SPI Flash / assets de los juegos (hardware/grupo_D_spiflash) — 0x420000-0x42FFFF ----
#define FLASH_BASE   0x00420000
#define FLASH_STATUS (*(volatile unsigned int*)0x0042FFFC)

// ---- Grupo E: Teclado PS/2 (hardware/grupo_E_ps2_keyboard) — 0x430000-0x43FFFF ----
#define KBD_DATA   (*(volatile unsigned int*)0x00430000)
#define KBD_STATUS (*(volatile unsigned int*)0x00430004)

// ---- Grupo F: Mouse PS/2 (hardware/grupo_F_ps2_mouse) — 0x440000-0x44FFFF ----
#define MOUSE_STATUS (*(volatile unsigned int*)0x00440000)
#define MOUSE_DX     (*(volatile int*)0x00440004)
#define MOUSE_DY     (*(volatile int*)0x00440008)
#define MOUSE_VALID  (*(volatile unsigned int*)0x0044000C)

// ---- Grupo G: 8 controles NES (hardware/grupo_G_nes_controller) — 0x450000-0x45FFFF ----
// bit0=A, bit1=B, bit2=Select, bit3=Start, bit4=Up, bit5=Down, bit6=Left, bit7=Right
#define NES_P1 (*(volatile unsigned int*)0x00450000) // Pantalla 1, jugador A
#define NES_P2 (*(volatile unsigned int*)0x00450004) // Pantalla 1, jugador B
#define NES_P3 (*(volatile unsigned int*)0x00450008) // Pantalla 2, jugador A
#define NES_P4 (*(volatile unsigned int*)0x0045000C) // Pantalla 2, jugador B
#define NES_P5 (*(volatile unsigned int*)0x00450010) // Pantalla 3, jugador A
#define NES_P6 (*(volatile unsigned int*)0x00450014) // Pantalla 3, jugador B
#define NES_P7 (*(volatile unsigned int*)0x00450018) // Pantalla 4, jugador A
#define NES_P8 (*(volatile unsigned int*)0x0045001C) // Pantalla 4, jugador B

#define BOTON_A      0x01
#define BOTON_B      0x02
#define BOTON_SELECT 0x04
#define BOTON_START  0x08
#define BOTON_ARRIBA 0x10
#define BOTON_ABAJO  0x20
#define BOTON_IZQ    0x40
#define BOTON_DER    0x80

// ---- Grupo H: I2C (hardware/grupo_H_i2c) — 0x460000-0x46FFFF ----
#define I2C_ADDR   (*(volatile unsigned int*)0x00460000)
#define I2C_DATA   (*(volatile unsigned int*)0x00460004)
#define I2C_CTRL   (*(volatile unsigned int*)0x00460008)
#define I2C_STATUS (*(volatile unsigned int*)0x0046000C)

// ---- Grupo I: Audio I2S, 4 canales independientes (hardware/grupo_I_i2s) — 0x470000-0x47FFFF ----
#define AUDIO1_DATA  (*(volatile int*)0x00470000) // Pantalla 1
#define AUDIO2_DATA  (*(volatile int*)0x00470004) // Pantalla 2
#define AUDIO3_DATA  (*(volatile int*)0x00470008) // Pantalla 3
#define AUDIO4_DATA  (*(volatile int*)0x0047000C) // Pantalla 4
#define AUDIO_STATUS (*(volatile unsigned int*)0x00470010)

// ---- Grupo J: Framebuffers de las 4 pantallas (hardware/grupo_J_display) — 0x480000-0x4FFFFF (512KB) ----
// 128KB por pantalla (0x20000) -- resuelve el problema de tamano que
// teniamos con la ventana propia de 16KB/pantalla: a 640x480x12bpp un
// framebuffer completo pesa ~460KB (no cabe), pero SI cabe a una
// resolucion reducida (ver hardware/grupo_J_display/README.md).
#define FB1_BASE 0x00480000 // Pantalla 1
#define FB2_BASE 0x004A0000 // Pantalla 2
#define FB3_BASE 0x004C0000 // Pantalla 3
#define FB4_BASE 0x004E0000 // Pantalla 4

#endif
