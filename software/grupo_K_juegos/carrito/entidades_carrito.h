// entidades_carrito.h — estructuras de datos internas del juego del
// Carrito.
//
// ESTRUCTURA, no logica: son los "sustantivos" que carrito.c va a
// usar. Ningun campo tiene valores todavia y ninguna funcion que los
// modifique esta implementada aqui -- eso es trabajo de carrito.c (no
// existe todavia).

#ifndef ENTIDADES_CARRITO_H
#define ENTIDADES_CARRITO_H

// La pista se modela como carriles discretos (no posicion X libre) --
// mas simple de dibujar en baja resolucion y de detectar colisiones.
#define NUM_CARRILES     3
#define MAX_OBSTACULOS   6

// Carro del jugador: solo necesita saber en que carril esta.
typedef struct {
    int carril;   // 0 .. NUM_CARRILES-1
} Carro;

// Un obstaculo que baja por la pista (efecto de scroll = la pista se
// mueve, no el carro).
typedef struct {
    int carril;
    int y;        // posicion vertical; aumenta segun velocidad_scroll
    int activo;   // 0 = slot libre, no se dibuja ni se actualiza
} Obstaculo;

// Estado interno completo de una partida del Carrito.
typedef struct {
    Carro carro;
    Obstaculo obstaculos[MAX_OBSTACULOS];
    int velocidad_scroll;         // pixeles/celdas que bajan los obstaculos por cuadro
    int distancia_recorrida;      // puntaje: aumenta con el tiempo/obstaculos esquivados
    int contador_generacion;      // cuadros desde el ultimo obstaculo generado
    int cuadros_entre_obstaculos; // baja con el tiempo = aparecen mas seguido (mas dificil)
} EstadoCarrito;

#endif
