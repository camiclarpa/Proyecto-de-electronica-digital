// juego.h — LA INTERFAZ QUE TODO JUEGO DEBE IMPLEMENTAR
//
// Esto es estructura, no logica: define el CONTRATO que Pong, Space
// Invaders, Snake y Carrito deben cumplir para poder conectarse al
// mismo main.c sin que este tenga que conocer las reglas de cada uno.
//
// Cada juego, en su propio .c (todavia sin escribir), va a rellenar
// estos punteros a funcion con sus propias implementaciones.

#ifndef JUEGO_H
#define JUEGO_H

#include "estado_sistema.h"

typedef struct {
    // Se llama UNA VEZ al entrar al juego desde el menu.
    // Debe dejar todas sus variables globales/estado en un punto de
    // partida limpio (ver docs/manejo_errores_y_seguridad.md: el
    // sistema debe poder reiniciar un juego sin reiniciar los otros 3).
    void (*inicializar)(void);

    // Se llama en cada iteracion del bucle principal (ver
    // docs/logica_juegos.md para la maquina de estados esperada).
    // botones_p1/p2: lectura cruda de NES_Px (hardware/grupo_G_nes_controller)
    // Debe devolver el nuevo EstadoJuego (Jugando, Pausa, FinPartida, etc.)
    EstadoJuego (*actualizar)(unsigned int botones_p1, unsigned int botones_p2);

    // Se llama despues de actualizar(), para dibujar el frame actual
    // sobre el framebuffer de ESTA pantalla (ver comun/framebuffer.h).
    void (*dibujar)(void);

    // Se llama cuando el jugador pausa (boton Select) -- opcional,
    // puede quedar vacio si el juego no necesita nada especial al pausar.
    void (*al_pausar)(void);

    // Se llama al reanudar desde pausa.
    void (*al_reanudar)(void);

    // Nombre del juego, para mostrarlo en el menu (ver comun/main.c)
    const char* nombre;
} InterfazJuego;

#endif
