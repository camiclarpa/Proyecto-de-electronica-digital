# comun/ — Estructura compartida por los 4 juegos

Todo lo que hay aquí es **contrato/estructura**, no lógica de juego:

| Archivo | Qué define | Contiene lógica? |
|---|---|---|
| [`juego.h`](juego.h) | La interfaz `InterfazJuego` que Pong/Space Invaders/Snake/Carrito deben implementar | No — solo el `struct` con punteros a función |
| [`estado_sistema.h`](estado_sistema.h) | Los 7 estados posibles de un juego (Menu, Jugando, Pausa, etc.) | No — solo el `enum` |
| [`perifericos.h`](perifericos.h) | Todas las direcciones de hardware en un solo lugar, tomadas de cada `hardware/grupo_*/README.md` | No — solo `#define` |
| [`framebuffer.h`](framebuffer.h) | Las funciones de dibujo que todos los juegos van a usar | No — solo prototipos, sin implementar |
| [`Makefile`](Makefile) | Cómo se compilan y enlazan todos los `.c` en un solo `.elf` para el RISC-V | No — es configuración de compilación |

**`main.c` todavía no existe.** Cuando se escriba, va a ser el único
archivo con lógica real de este grupo de "estructura" — y su trabajo va
a ser muy acotado: leer qué pantalla es, elegir la `InterfazJuego`
correcta, y llamar sus funciones en bucle. Toda la lógica de CADA juego
vive en su propia carpeta (`../pong/`, `../snake/`, etc.), no aquí.

## Por qué esta separación importa

Si cualquier persona del equipo (o de otro grupo, si llegan a
necesitar ayuda del Grupo K) quiere entender cómo se conecta un juego
nuevo al sistema, solo necesita leer `juego.h` — no necesita entender
Pong, Snake, ni ningún juego en particular. Esa es la señal de que la
estructura está bien separada de la implementación.
