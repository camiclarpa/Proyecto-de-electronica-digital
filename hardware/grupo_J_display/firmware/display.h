#ifndef DISPLAY_H
#define DISPLAY_H

#include <stdint.h>

// Direcciones OFICIALES confirmadas 2026-09-16 (ver
// ../../../docs/mapa_memoria.md). Cada pantalla tiene su propia
// ventana de 128 KB para el framebuffer -- el CPU NO controla el
// timing VGA (eso lo hace el hardware solo, ver rtl/vga_timing.v),
// solo escribe pixeles en la ventana de su pantalla.
#define FB1_BASE 0x00480000u // Pantalla 1 — 0x480000-0x49FFFF
#define FB2_BASE 0x004A0000u // Pantalla 2 — 0x4A0000-0x4BFFFF
#define FB3_BASE 0x004C0000u // Pantalla 3 — 0x4C0000-0x4DFFFF
#define FB4_BASE 0x004E0000u // Pantalla 4 — 0x4E0000-0x4FFFFF

#define FB_WINDOW_SIZE 0x00020000u // 128 KB por pantalla

// Las funciones de dibujo (limpiar_pantalla, poner_pixel,
// dibujar_sprite, dibujar_texto) NO se redefinen aqui -- ya estan
// declaradas y son compartidas por los 4 juegos en
// software/grupo_K_juegos/comun/framebuffer.h. Este archivo solo
// aporta las direcciones base oficiales de hardware que esas funciones
// reciben como parametro `fb_base` (una de las 4 macros de arriba).

#endif
