// pong.h — declaracion de la InterfazJuego de Pong.
// Esto es ESTRUCTURA, no implementacion: aqui solo se declara que Pong
// va a existir y va a cumplir el contrato de ../comun/juego.h. Las
// funciones (pong_inicializar, pong_actualizar, etc.) se implementan
// en pong.c, que todavia no se ha escrito.

#ifndef PONG_H
#define PONG_H

#include "../comun/juego.h"

// Instancia que main.c va a usar para jugar Pong, sin necesitar saber
// nada de como funciona Pong por dentro.
extern const InterfazJuego JUEGO_PONG;

#endif
