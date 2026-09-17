# Pong

Dos paletas, una pelota, primero en llegar al puntaje máximo gana. Multijugador local (2 jugadores, 2 controles NES — `NES_P1`, `NES_P2`).

Sigue la máquina de estados general documentada en
[`docs/logica_juegos.md`](../../../docs/logica_juegos.md)
(Menu → Configurando → Jugando → Pausa/Punto → FinPartida → ErrorControl/ErrorFatal).
Este documento detalla la lógica **específica** de Pong dentro del estado `ESTADO_JUGANDO`.

## Estructura de código (sin lógica todavía)

Este juego se conecta al resto del sistema implementando la interfaz
`InterfazJuego` definida en [`../comun/juego.h`](../comun/juego.h).
Ya existe la declaración de esa conexión en [`pong.h`](pong.h):

```c
extern const InterfazJuego JUEGO_PONG;
```

Las estructuras de datos internas (qué necesita recordar Pong entre un
cuadro y el siguiente) ya están declaradas en
[`entidades_pong.h`](entidades_pong.h):

```c
typedef struct { int y; int alto; int velocidad; } Paleta;
typedef struct { int x, y; int vx, vy; int velocidad_base; } Pelota;
typedef struct { Paleta jugador1; Paleta jugador2; Pelota pelota; int puntaje1; int puntaje2; int puntaje_maximo; } EstadoPong;
```

Falta por crear `pong.c`, donde se va a definir `JUEGO_PONG` y a
implementar la lógica real sobre `EstadoPong`. `main.c` (en
`../comun/`) solo va a conocer `JUEGO_PONG` a través de `pong.h` —
nunca va a necesitar saber cómo funciona Pong por dentro.

### Estructura de carpetas de este juego

```
pong/
├── README.md              (este archivo)
├── pong.h                 — contrato: declara JUEGO_PONG (InterfazJuego)
├── entidades_pong.h        — estructuras internas: Paleta, Pelota, EstadoPong
├── mockup_pantalla.svg     — mockup visual de cómo se va a ver la pantalla
└── pong.c                 — (no existe aún) implementación real
```

## Entidades

| Entidad | Struct | Descripción |
|---|---|---|
| Paleta jugador 1 | `Paleta` | Lado izquierdo, se mueve vertical, controlada por `NES_P1` |
| Paleta jugador 2 | `Paleta` | Lado derecho, se mueve vertical, controlada por `NES_P2` |
| Pelota | `Pelota` | Se mueve en línea recta, rebota contra paredes y paletas |
| Marcador | `int, int` (en `EstadoPong`) | Puntaje de cada jugador, contra `puntaje_maximo` |

## Controles (NES, ver `hardware/grupo_G_nes_controller`)

| Botón | Jugador 1 (`NES_P1`) | Jugador 2 (`NES_P2`) |
|---|---|---|
| `BOTON_ARRIBA` | Subir paleta | Subir paleta |
| `BOTON_ABAJO` | Bajar paleta | Bajar paleta |
| `BOTON_START` | Pausar / reanudar (cualquiera de los dos) | ídem |
| Resto de botones | Sin uso en este juego | Sin uso en este juego |

## Mockup de la pantalla

<img src="mockup_pantalla.svg" width="820" alt="Mockup de la pantalla de Pong: paletas a los lados, pelota al centro, marcador arriba">

## Diagrama de bloques (arquitectura interna)

Organización jerárquica: **Entrada → Lógica de Pong (sobre `EstadoPong`) → Salida**. Ningún bloque de "Lógica" conoce el hardware directamente — todos pasan por `perifericos.h` o `framebuffer.h`.

```mermaid
flowchart TB
    subgraph ENTRADA["① ENTRADA"]
        direction TB
        A1["Leer NES_P1 / NES_P2\n(perifericos.h)"]
    end

    subgraph LOGICA["② LÓGICA DE PONG (pong.c, sobre EstadoPong)"]
        direction TB
        L1["Mover paletas\n(jugador1, jugador2)"]
        L2["Mover pelota\n(pelota.x/y += vx/vy)"]
        L3["Detectar colisiones\n(paredes, paletas)"]
        L4["Actualizar marcador\n(puntaje1, puntaje2)"]
        L1 --> L2 --> L3 --> L4
    end

    subgraph SALIDA["③ SALIDA"]
        direction TB
        S1["Dibujar paletas + pelota\n(framebuffer.h: poner_pixel / dibujar_sprite)"]
        S2["Dibujar marcador\n(framebuffer.h: dibujar_texto)"]
        S3["Sonido de rebote/punto\n(perifericos.h: AUDIOn_DATA)"]
    end

    ENTRADA --> LOGICA --> SALIDA
```

## Diagrama de flujo (lógica de un cuadro en `ESTADO_JUGANDO`)

**Convenciones del diagrama** (simbología estándar de diagramas de flujo):

| Símbolo | Significado |
|---|---|
| ⬭ Óvalo (terminal) | Inicio / fin del flujo |
| ▱ Paralelogramo | Entrada o salida de datos |
| ▭ Rectángulo | Proceso / acción |
| ◇ Rombo | Decisión (condicional, dos salidas) |

```mermaid
flowchart TD
    Inicio(["Inicio de cuadro\n(ESTADO_JUGANDO)"])
    Entrada[/"Leer NES_P1, NES_P2"/]
    Mover["Mover paleta1 y paleta2\nsegún BOTON_ARRIBA/ABAJO"]
    MoverPelota["Mover pelota:\nx += vx, y += vy"]

    ChoquePared{"¿Pelota tocó\nborde superior\no inferior?"}
    InvertirVY["Invertir pelota.vy"]

    ChoquePaleta{"¿Pelota tocó\nalguna paleta?"}
    InvertirVX["Invertir pelota.vx\n+ ajustar vy según punto\nde impacto + acelerar"]

    SalioX{"¿Pelota salió\npor la izquierda\no la derecha?"}
    Punto["Sumar punto al\noponente + reiniciar\npelota al centro"]

    FinJuego{"¿Algún puntaje\n== puntaje_maximo?"}

    Dibujar[/"Dibujar frame\n(framebuffer.h)"/]
    Sonido[/"Reproducir sonido\nde rebote/punto"/]

    Fin(["Fin de cuadro →\ndevolver EstadoJuego"])
    FinPartida(["Devolver\nESTADO_FIN_PARTIDA"])

    Inicio --> Entrada --> Mover --> MoverPelota --> ChoquePared
    ChoquePared -- "Sí" --> InvertirVY --> ChoquePaleta
    ChoquePared -- "No" --> ChoquePaleta

    ChoquePaleta -- "Sí" --> InvertirVX --> Sonido --> SalioX
    ChoquePaleta -- "No" --> SalioX

    SalioX -- "Sí" --> Punto --> Sonido2[/"Reproducir sonido\nde punto"/] --> FinJuego
    SalioX -- "No" --> Dibujar --> Fin

    FinJuego -- "Sí" --> FinPartida
    FinJuego -- "No" --> Dibujar
```

## Estado
- [x] Lógica del juego diseñada (diagramas de arriba)
- [x] Estructura de código creada (`pong.h`, `entidades_pong.h`)
- [x] Mockup visual de la pantalla
- [ ] Implementado en C sobre el RISC-V (femtoriscv) — falta `pong.c`
- [ ] Probado con los periféricos reales (control, pantalla, sonido)
- [ ] Manejo de errores implementado (ver `docs/manejo_errores_y_seguridad.md`)

## Assets necesarios (sprites, sonidos)
- Sprite de paleta (rectángulo simple, puede ser 1 solo color)
- Sprite de pelota (cuadrado simple)
- Fuente bitmap para el marcador (reutiliza `framebuffer.h: dibujar_texto`)
- Sonido de rebote (corto, ~50ms) y sonido de punto (corto, distinto tono)

## Integrantes responsables de este juego
-
