// framebuffer.h — funciones de dibujo compartidas por los 4 juegos.
// Solo declaraciones (contrato) -- la implementacion real de cada
// funcion todavia no se ha escrito, queda para cuando el equipo decida
// la resolucion final (ver hardware/grupo_J_display/README.md).

#ifndef FRAMEBUFFER_H
#define FRAMEBUFFER_H

// Cada juego solo dibuja en SU framebuffer (fb_base), nunca en el de
// otra pantalla -- esto es lo que garantiza el aislamiento de fallos
// documentado en docs/manejo_errores_y_seguridad.md.

void limpiar_pantalla(unsigned int fb_base, unsigned short color);

void poner_pixel(unsigned int fb_base, int x, int y, unsigned short color);

// Dibuja un sprite pre-cargado (arreglo de colores de ancho x alto)
// en la posicion (x, y) del framebuffer indicado.
void dibujar_sprite(unsigned int fb_base, int x, int y,
                    const unsigned short* sprite, int ancho, int alto);

// Dibuja texto simple (para puntajes, "GAME OVER", etc.) usando una
// fuente de mapa de bits basica -- formato de la fuente por definir.
void dibujar_texto(unsigned int fb_base, int x, int y, const char* texto, unsigned short color);

#endif
