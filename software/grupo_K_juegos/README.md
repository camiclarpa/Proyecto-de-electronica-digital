# Grupo K — Software de los juegos

**Esto es la estructura del código, no el código en sí.** Define cómo se
va a organizar el software antes de escribir una sola línea de lógica
de juego — igual que se hizo con los contratos de cada módulo de
`hardware/`, para que los 4 juegos se integren de forma consistente
entre sí y con el resto de los grupos.

## Filosofía de la estructura

Cada uno de los 4 juegos (Pong, Space Invaders, Snake, Carrito) es un
módulo independiente que implementa **la misma interfaz común**
(`InterfazJuego`, definida en [`comun/juego.h`](comun/juego.h)). El
programa principal (`comun/main.c`) no sabe nada de las reglas
particulares de cada juego — solo sabe llamar `inicializar()`,
`actualizar()` y `dibujar()` sobre "el juego que esté activo en esta
pantalla". Esto es lo mismo que ya documentamos como máquina de estados
en [`../../docs/logica_juegos.md`](../../docs/logica_juegos.md), llevado
a una estructura de código real.

## Estructura de carpetas

```
software/grupo_K_juegos/
├── README.md                    (este archivo)
├── comun/                       — código y contratos compartidos por los 4 juegos
│   ├── juego.h                  — la interfaz que todo juego debe implementar
│   ├── perifericos.h            — un solo lugar con todas las direcciones de hardware (de las 10 carpetas hardware/grupo_*)
│   ├── framebuffer.h            — funciones de dibujo compartidas (poner_pixel, dibujar_sprite, limpiar_pantalla)
│   ├── estado_sistema.h         — la maquina de estados general (Menu/Configurando/Jugando/Pausa/FinPartida/Error)
│   ├── main.c                   — (structure only, sin implementar aun) el bucle principal: boot -> menu -> dispatch al juego activo
│   └── Makefile                 — como se compilan y enlazan main.c + el juego activo en un solo .elf para el RISC-V
├── pong/
│   ├── pong.h                   — declara que pong implementa InterfazJuego
│   └── README.md
├── space_invaders/
│   ├── space_invaders.h
│   └── README.md
├── snake/
│   ├── snake.h
│   └── README.md
└── carrito/
    ├── carrito.h
    └── README.md
```

## Cómo un juego "se conecta" al sistema (sin escribir su lógica todavía)

1. Cada carpeta de juego declara una variable global del tipo
   `InterfazJuego` (ver `comun/juego.h`) con sus 5 punteros a función
   apuntando a sus propias funciones (ej. `pong_inicializar`,
   `pong_actualizar`, etc.) — **eso sí requiere código**, pero el
   contrato/estructura ya está definido de antemano en este commit.
2. `comun/main.c` decide, según en qué pantalla está corriendo (1 a 4,
   ver `hardware/grupo_G_nes_controller/`), cuál `InterfazJuego` usar,
   y desde ahí solo llama las funciones genéricas — nunca conoce el
   nombre "Pong" ni "Snake" directamente.
3. Esto significa que **agregar un quinto juego en el futuro no
   requeriría tocar `main.c`** — solo agregar su carpeta con su propia
   implementación de la interfaz.

## Sobre el multiplexado entre las 4 pantallas

**✅ DECISIÓN CERRADA (2026-09-16): Opción A — round-robin cooperativo.**

Dado que hay un solo CPU RISC-V (femtoriscv) y 4 pantallas corriendo 4
juegos distintos al mismo tiempo, se evaluaron dos formas reales de
estructurar esto:

| Opción | Cómo funciona | Complejidad |
|---|---|---|
| **A. Round-robin cooperativo** ✅ ELEGIDA | Un solo hilo de ejecución; el bucle principal llama `actualizar()` y `dibujar()` de cada uno de los 4 juegos por turnos, muy rápido (cada juego avanza "un cuadro" y devuelve el control antes de pasar al siguiente) | Más simple: no requiere guardar/restaurar registros ni pila |
| **B. 4 "tareas" con cambio de contexto real** ❌ descartada para v1 | Requiere guardar/restaurar el estado de la pila (stack) de cada juego al cambiar entre ellos — como un mini sistema operativo con 4 procesos | Requiere escribir un mini-scheduler en ensamblador RISC-V (guardar/restaurar registros, punteros de pila) — trabajo de sistemas embebidos que no aporta valor al objetivo del curso |

**Por qué se cierra en A y no en B:**

1. **El motivo original para considerar B era el aislamiento de fallos
   (un juego "colgado" no debería bloquear a los otros 3)** — pero ese
   aislamiento ya está resuelto en una capa distinta, sin necesitar un
   scheduler real: cada juego debe detectar su propio estado inválido y
   devolver `ESTADO_ERROR_CONTROL` o `ESTADO_ERROR_FATAL` (ver
   [`docs/manejo_errores_y_seguridad.md`](../../docs/manejo_errores_y_seguridad.md)),
   y el watchdog de hardware resetea solo esa pantalla. Esto funciona
   igual de bien bajo A que bajo B.
2. **B requiere infraestructura que no existe todavía**: sin un RTOS,
   implementar cambio de contexto real en RV32I significa escribir a
   mano el guardado/restauración del banco de registros y el stack
   pointer de cada "tarea" — riesgo de bugs de bajo nivel muy difíciles
   de depurar, para un equipo sin experiencia previa en esto y con el
   tiempo del curso como límite.
3. **Riesgo residual aceptado de A**: si el `actualizar()` o `dibujar()`
   de UN juego entra en un bucle infinito o un cálculo sin límite,
   congela las otras 3 pantallas también (no hay preemption). Mitigación
   adoptada: regla de código — cada `actualizar()`/`dibujar()` debe hacer
   trabajo acotado de un solo cuadro, sin esperas bloqueantes ni bucles
   sin límite superior — verificable en revisión de código de cada
   juego. Como respaldo final, el watchdog de hardware ya documentado en
   `docs/manejo_errores_y_seguridad.md` reinicia todo el sistema si deja
   de avanzar por completo.

Opción B queda como mejora válida para una v2 (mejor aislamiento de
fallos), no descartada permanentemente — solo fuera del alcance de la
primera entrega.

## Pendiente
- [x] Decidir Opción A vs B (arriba) — cerrado 2026-09-16
- [ ] Confirmar el mapa de memoria final contra `chip_select.v` real
  del proyecto femtoriscv, antes de fijar las direcciones en
  `comun/perifericos.h`
- [ ] Una vez cerrada la estructura, cada juego implementa su propia
  lógica dentro de su carpeta

## Integrantes responsables
-
