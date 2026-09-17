# Snake

La serpiente crece al comer, pierde al chocar contra el borde o contra sí misma.

Sigue la máquina de estados general documentada en
[`docs/logica_juegos.md`](../../../docs/logica_juegos.md)
(Menu → Configurando → Jugando → Pausa/Punto → FinPartida → ErrorControl/ErrorFatal).

## Estructura de código (sin lógica todavía)

Este juego se conecta al resto del sistema implementando la interfaz
`InterfazJuego` definida en [`../comun/juego.h`](../comun/juego.h).
Ya existe la declaración de esa conexión en [`snake.h`](snake.h):

```c
extern const InterfazJuego JUEGO_SNAKE;
```

Falta por crear `snake.c`, donde se va a definir `JUEGO_SNAKE` con las
funciones reales (`inicializar`, `actualizar`, `dibujar`, etc.).
`main.c` (en `../comun/`) solo va a conocer `JUEGO_SNAKE` a través de
`snake.h` — nunca va a necesitar saber cómo funciona Snake por dentro.

## Estado
- [ ] Lógica del juego diseñada (esta máquina de estados específica)
- [x] Estructura de código creada (`snake.h` con la declaración de `InterfazJuego`)
- [ ] Implementado en C sobre el RISC-V (femtoriscv) — falta `snake.c`
- [ ] Probado con los periféricos reales (control, pantalla, sonido)
- [ ] Manejo de errores implementado (ver `docs/manejo_errores_y_seguridad.md`)

## Assets necesarios (sprites, sonidos)
- 

## Integrantes responsables de este juego
- 
