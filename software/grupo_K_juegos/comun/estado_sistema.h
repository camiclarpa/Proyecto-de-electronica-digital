// estado_sistema.h — la maquina de estados general, en forma de
// estructura de codigo (enum), tal como esta documentada en
// docs/logica_juegos.md. Ningun estado tiene logica aqui todavia,
// solo se nombran para que main.c y cada juego hablen el mismo
// "idioma" de estados.

#ifndef ESTADO_SISTEMA_H
#define ESTADO_SISTEMA_H

typedef enum {
    ESTADO_MENU,
    ESTADO_CONFIGURANDO,
    ESTADO_JUGANDO,
    ESTADO_PAUSA,
    ESTADO_FIN_PARTIDA,
    ESTADO_ERROR_CONTROL,   // ver docs/manejo_errores_y_seguridad.md
    ESTADO_ERROR_FATAL      // watchdog: se reinicia SOLO este juego, no el sistema
} EstadoJuego;

#endif
