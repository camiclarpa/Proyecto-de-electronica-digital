// entidades_pong.h — estructuras de datos internas de Pong.
//
// ESTRUCTURA, no logica: son los "sustantivos" que pong.c va a usar
// para llevar el estado del juego. Ningun campo tiene valores todavia
// y ninguna funcion que los modifique esta implementada aqui -- eso es
// trabajo de pong.c (no existe todavia).

#ifndef ENTIDADES_PONG_H
#define ENTIDADES_PONG_H

// Paleta de un jugador: rectangulo vertical que se mueve arriba/abajo
// dentro de los limites del framebuffer.
typedef struct {
    int y;              // posicion vertical de la esquina superior (pixeles)
    int alto;           // alto en pixeles, fijo al inicializar
    int velocidad;      // pixeles que se mueve por cuadro al presionar Arriba/Abajo
} Paleta;

// Pelota: se mueve en linea recta hasta rebotar contra pared o paleta.
typedef struct {
    int x, y;            // posicion actual (esquina superior del sprite)
    int vx, vy;          // velocidad actual en X/Y (con signo, define direccion)
    int velocidad_base;  // velocidad al sacar/reiniciar, antes de acelerar por rebotes
} Pelota;

// Estado interno completo de una partida de Pong -- lo que pong.c
// necesita recordar entre un cuadro y el siguiente.
typedef struct {
    Paleta jugador1;      // lado izquierdo, controlado por NES_P1
    Paleta jugador2;      // lado derecho, controlado por NES_P2
    Pelota pelota;
    int puntaje1;
    int puntaje2;
    int puntaje_maximo;   // puntaje para ganar la partida (ver README.md)
} EstadoPong;

#endif
