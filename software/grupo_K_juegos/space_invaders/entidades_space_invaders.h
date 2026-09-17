// entidades_space_invaders.h — estructuras de datos internas de
// Space Invaders.
//
// ESTRUCTURA, no logica: son los "sustantivos" que space_invaders.c va
// a usar. Ningun campo tiene valores todavia y ninguna funcion que los
// modifique esta implementada aqui -- eso es trabajo de
// space_invaders.c (no existe todavia).

#ifndef ENTIDADES_SPACE_INVADERS_H
#define ENTIDADES_SPACE_INVADERS_H

#define FILAS_ENEMIGOS      5
#define COLUMNAS_ENEMIGOS   8
#define MAX_PROYECTILES_JUGADOR  4  // varios proyectiles a la vez, con cooldown
#define MAX_PROYECTILES_ENEMIGOS 4  // varios enemigos pueden disparar a la vez

// Nave del jugador: se mueve solo en X, en la fila inferior.
typedef struct {
    int x;
    int vidas;
} Jugador;

// Un enemigo individual de la formacion.
typedef struct {
    int x, y;
    int vivo;   // 0 = ya fue destruido
} Enemigo;

// La formacion completa de enemigos se mueve y acelera como un solo
// bloque (comportamiento clasico del juego original).
typedef struct {
    Enemigo enemigos[FILAS_ENEMIGOS][COLUMNAS_ENEMIGOS];
    int direccion;        // +1 = moviendose a la derecha, -1 = a la izquierda
    int velocidad;        // aumenta conforme quedan menos enemigos vivos
    int enemigos_vivos;   // contador para saber cuando termina la oleada
}  GridEnemigos;

// Un proyectil: del jugador (sube) o de un enemigo (baja) -- el signo
// de vy define la direccion, asi que es la misma estructura para ambos.
typedef struct {
    int x, y;
    int vy;
    int activo;   // 0 = no se esta dibujando/actualizando (slot libre)
} Proyectil;

// Estado interno completo de una partida de Space Invaders.
typedef struct {
    Jugador jugador;
    GridEnemigos enemigos;
    Proyectil balas_jugador[MAX_PROYECTILES_JUGADOR];
    Proyectil balas_enemigos[MAX_PROYECTILES_ENEMIGOS];
    int oleada;     // numero de oleada actual (dificultad progresiva)
    int puntaje;
} EstadoSpaceInvaders;

#endif
