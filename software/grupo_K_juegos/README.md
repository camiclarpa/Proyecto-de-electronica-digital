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

**[DECISIÓN PENDIENTE — para el equipo]**: dado que hay un solo CPU
RISC-V (femtoriscv) y 4 pantallas corriendo 4 juegos distintos al mismo
tiempo, hay dos formas reales de estructurar esto, y hay que elegir una
antes de escribir `main.c`:

| Opción | Cómo funciona | Complejidad |
|---|---|---|
| **A. Round-robin cooperativo** | Un solo hilo de ejecución; el bucle principal llama `actualizar()` y `dibujar()` de cada uno de los 4 juegos por turnos, muy rápido (ej. cada juego avanza "un poco" antes de pasar al siguiente) | Más simple de implementar en un CPU sin sistema operativo |
| **B. 4 "tareas" con cambio de contexto real** | Requiere guardar/restaurar el estado de la pila (stack) de cada juego al cambiar entre ellos — como un mini sistema operativo con 4 procesos | Más complejo, pero permite que un juego "colgado" no bloquee a los otros (mejor aislamiento de fallos, ver `docs/manejo_errores_y_seguridad.md`) |

**Recomendación**: empezar por la Opción A (round-robin cooperativo) —
es la que un equipo sin experiencia previa en sistemas embebidos puede
implementar de forma confiable en el tiempo del curso. La Opción B es
un refinamiento válido para una v2, no para la primera entrega.

## Pendiente
- [ ] Decidir Opción A vs B (arriba)
- [ ] Confirmar el mapa de memoria final contra `chip_select.v` real
  del proyecto femtoriscv, antes de fijar las direcciones en
  `comun/perifericos.h`
- [ ] Una vez cerrada la estructura, cada juego implementa su propia
  lógica dentro de su carpeta

## Integrantes responsables
-
