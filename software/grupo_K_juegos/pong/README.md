# Pong

Dos paletas, una pelota, primero en llegar al puntaje máximo gana. Multijugador local (2 jugadores, 2 controles).

Sigue la máquina de estados general documentada en
[`docs/logica_juegos.md`](../../../docs/logica_juegos.md)
(Menu → Configurando → Jugando → Pausa/Punto → FinPartida → ErrorControl/ErrorFatal).

## Estructura de código (sin lógica todavía)

Este juego se conecta al resto del sistema implementando la interfaz
`InterfazJuego` definida en [`../comun/juego.h`](../comun/juego.h).
Ya existe la declaración de esa conexión en [`pong.h`](pong.h):

```c
extern const InterfazJuego JUEGO_PONG;
```

Falta por crear `pong.c`, donde se va a definir `JUEGO_PONG` con las
funciones reales (`pong_inicializar`, `pong_actualizar`, `pong_dibujar`,
etc.). `main.c` (en `../comun/`) solo va a conocer `JUEGO_PONG` a través
de `pong.h` — nunca va a necesitar saber cómo funciona Pong por dentro.

## Estado
- [ ] Lógica del juego diseñada (esta máquina de estados específica)
- [x] Estructura de código creada (`pong.h` con la declaración de `InterfazJuego`)
- [ ] Implementado en C sobre el RISC-V (femtoriscv) — falta `pong.c`
- [ ] Probado con los periféricos reales (control, pantalla, sonido)
- [ ] Manejo de errores implementado (ver `docs/manejo_errores_y_seguridad.md`)

## Assets necesarios (sprites, sonidos)
- 

## Integrantes responsables de este juego
- 
