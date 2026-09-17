// entidades_snake.h — estructuras de datos internas de Snake.
//
// ESTRUCTURA, no logica: son los "sustantivos" que snake.c va a usar.
// Ningun campo tiene valores todavia y ninguna funcion que los
// modifique esta implementada aqui -- eso es trabajo de snake.c (no
// existe todavia).

#ifndef ENTIDADES_SNAKE_H
#define ENTIDADES_SNAKE_H

// Snake se mueve sobre una grilla discreta (celdas), no en pixeles
// libres -- por eso las coordenadas son indices de celda, no pixeles.
typedef struct {
    int x, y;
} Punto;

typedef enum {
    DIR_ARRIBA,
    DIR_ABAJO,
    DIR_IZQUIERDA,
    DIR_DERECHA
} Direccion;

// Limite superior de longitud, segun el tamano de grilla que se defina
// (a confirmar junto con la resolucion real, ver hardware/grupo_J_display).
#define MAX_SEGMENTOS_SERPIENTE 256

typedef struct {
    Punto segmentos[MAX_SEGMENTOS_SERPIENTE]; // segmentos[0] = cabeza
    int longitud;
    Direccion direccion_actual;
    Direccion direccion_deseada; // se acumula desde el ultimo input;
                                  // se aplica recien en el siguiente
                                  // "tick" de movimiento (ver README.md)
} Serpiente;

// Estado interno completo de una partida de Snake.
typedef struct {
    Serpiente serpiente;
    Punto comida;
    int puntaje;
    int contador_ticks;        // cuadros transcurridos desde el ultimo movimiento
    int ticks_por_movimiento;  // cuantos cuadros esperar entre movimientos;
                                // baja con el puntaje = la serpiente acelera
} EstadoSnake;

#endif
