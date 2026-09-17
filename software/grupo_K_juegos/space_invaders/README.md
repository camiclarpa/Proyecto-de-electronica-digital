# Space Invaders

Oleadas de enemigos que bajan, el jugador dispara desde abajo, pierde vidas al ser alcanzado.

Sigue la máquina de estados general documentada en
[`docs/logica_juegos.md`](../../../docs/logica_juegos.md)
(Menu → Configurando → Jugando → Pausa/Punto → FinPartida → ErrorControl/ErrorFatal).

## Estructura de código (sin lógica todavía)

Este juego se conecta al resto del sistema implementando la interfaz
`InterfazJuego` definida en [`../comun/juego.h`](../comun/juego.h).
Ya existe la declaración de esa conexión en [`space_invaders.h`](space_invaders.h):

```c
extern const InterfazJuego JUEGO_SPACE_INVADERS;
```

Falta por crear `space_invaders.c`, donde se va a definir
`JUEGO_SPACE_INVADERS` con las funciones reales (`inicializar`,
`actualizar`, `dibujar`, etc.). `main.c` (en `../comun/`) solo va a
conocer `JUEGO_SPACE_INVADERS` a través de `space_invaders.h` — nunca
va a necesitar saber cómo funciona el juego por dentro.

## Estado
- [ ] Lógica del juego diseñada (esta máquina de estados específica)
- [x] Estructura de código creada (`space_invaders.h` con la declaración de `InterfazJuego`)
- [ ] Implementado en C sobre el RISC-V (femtoriscv) — falta `space_invaders.c`
- [ ] Probado con los periféricos reales (control, pantalla, sonido)
- [ ] Manejo de errores implementado (ver `docs/manejo_errores_y_seguridad.md`)

## Assets necesarios (sprites, sonidos)
- 

## Integrantes responsables de este juego
- 
