# Juego de Carrito

Esquivar obstáculos en una pista que se desplaza, pierde al chocar.

Sigue la máquina de estados general documentada en
[`docs/logica_juegos.md`](../../../docs/logica_juegos.md)
(Menu → Configurando → Jugando → Pausa/Punto → FinPartida → ErrorControl/ErrorFatal).

## Estructura de código (sin lógica todavía)

Este juego se conecta al resto del sistema implementando la interfaz
`InterfazJuego` definida en [`../comun/juego.h`](../comun/juego.h).
Ya existe la declaración de esa conexión en [`carrito.h`](carrito.h):

```c
extern const InterfazJuego JUEGO_CARRITO;
```

Falta por crear `carrito.c`, donde se va a definir `JUEGO_CARRITO` con
las funciones reales (`inicializar`, `actualizar`, `dibujar`, etc.).
`main.c` (en `../comun/`) solo va a conocer `JUEGO_CARRITO` a través de
`carrito.h` — nunca va a necesitar saber cómo funciona el juego por dentro.

## Estado
- [ ] Lógica del juego diseñada (esta máquina de estados específica)
- [x] Estructura de código creada (`carrito.h` con la declaración de `InterfazJuego`)
- [ ] Implementado en C sobre el RISC-V (femtoriscv) — falta `carrito.c`
- [ ] Probado con los periféricos reales (control, pantalla, sonido)
- [ ] Manejo de errores implementado (ver `docs/manejo_errores_y_seguridad.md`)

## Assets necesarios (sprites, sonidos)
- 

## Integrantes responsables de este juego
- 
