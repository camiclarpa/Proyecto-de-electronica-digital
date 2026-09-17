# Proyecto de Electrónica Digital — Consola de 4 videojuegos en paralelo

Propuesta de sistema: una sola placa de desarrollo FPGA (Colorlight 5A-75E, con
un SoC RISC-V tipo femtoriscv como el del repositorio del curso) controla
**4 pantallas simultáneas**, cada una corriendo un juego distinto:
**Pong, Space Invaders, Snake y un juego de carrito**, con hasta 2 jugadores
locales por pantalla.

> Estado: propuesta inicial en construcción. Los supuestos marcados con
> **[SUPUESTO — confirmar]** son puntos donde las notas originales del grupo
> tenían una inconsistencia y se necesita decisión del equipo/profesor.

## 1. Supuestos que hay que confirmar

- **[SUPUESTO — confirmar]** Los controles de juego (Arriba/Abajo/Izquierda/
  Derecha/Start/Select/Botón A/Botón B) usan protocolo **estilo NES**
  (shift register: clock + latch + data), NO el bus PS/2. El PS/2 se reserva
  para teclado/mouse de depuración y configuración del sistema (Grupo E y
  Grupo F). Esto es porque el Grupo G ya existe como `nes_controller.v`,
  que es un protocolo distinto al PS/2.
- **[SUPUESTO — confirmar]** Son **8 controles físicos en total** (2 por
  cada una de las 4 pantallas, para multijugador local de hasta 2
  jugadores por juego) — no 4 controles como decía una nota suelta.

## 2. Entradas y salidas del sistema

**Entradas:**
- 8 controles tipo NES (2 por pantalla) — Grupo G
- Teclado PS/2 — Grupo E (configuración/depuración)
- Mouse PS/2 — Grupo F (configuración/depuración, si aplica)
- Alimentación externa (fuente única para las 4 pantallas)

**Salidas:**
- 4 salidas de video independientes (una por pantalla) — Grupo J
- 4 salidas de audio independientes (una por juego/pantalla) — Grupo I
- Control de brillo de las 4 pantallas

**Almacenamiento / memoria:**
- BRAM interna (Grupo A) — memoria de trabajo del CPU
- SPI RAM (Grupo C) — posible VRAM extendida para los framebuffers de las 4 pantallas
- SPI Flash (Grupo D) — sprites, assets y datos persistentes de cada juego
- I2C (Grupo H) — configuración de periféricos auxiliares (ej. controladores de pantalla/brillo, si aplica)

## 3. Arquitectura completa, mapa de memoria y relación entre los 11 grupos

El diagrama de bloques del sistema completo, el mapa de direcciones
consolidado de los 10 periféricos, y la tabla de relación entre los 11
grupos ahora viven en **[`docs/arquitectura_sistema.md`](docs/arquitectura_sistema.md)**
y **[`docs/mapa_memoria.md`](docs/mapa_memoria.md)** — se movieron ahí
para no mantener el mismo diagrama duplicado en dos lugares que se
desactualizan entre sí. El diagrama de flujo del software también se
movió y se amplió (uno por cada uno de los 4 juegos, con su propia
lógica): ver **[`docs/README.md`](docs/README.md)** para el índice
completo de toda la documentación técnica.

**Punto crítico de coordinación**: el Grupo K (software de los juegos)
no puede avanzar a implementación real hasta validar el mapa de memoria
propuesto contra el decodificador real (`chip_select.v`) del proyecto
femtoriscv del curso — ver [`docs/mapa_memoria.md`](docs/mapa_memoria.md).

## 4. Requisitos de hardware físico (mecánica/gabinete)

- Una caja/gabinete que aloje las 4 pantallas y los 8 botones/controles.
- Una única fuente de alimentación para las 4 pantallas.
- Control de brillo para las 4 pantallas.
- Consideración de experiencia de usuario y ergonomía física (altura,
  distancia entre controles, visibilidad de las 4 pantallas a la vez)
  — ver decisiones ya cerradas en [`docs/decisiones_cerradas.md`](docs/decisiones_cerradas.md).

## 5. Estructura de directorios (actual)

```
Proyecto-de-electronica-digital/
├── README.md                        (este archivo)
├── docs/
│   ├── README.md                    — índice de toda la documentación técnica
│   ├── arquitectura_sistema.md      — diagrama de bloques completo + relación entre los 11 grupos
│   ├── mapa_memoria.md              — direcciones de TODOS los periféricos, consolidadas
│   ├── logica_juegos.md             — máquina de estados general + enlaces a cada juego
│   ├── manejo_errores_y_seguridad.md — aislamiento de fallos + seguridad física
│   └── decisiones_cerradas.md       — registro central de decisiones del proyecto
├── hardware/
│   ├── grupo_A_bram/
│   ├── grupo_B_uart/
│   ├── grupo_C_spiram/
│   ├── grupo_D_spiflash/
│   ├── grupo_E_ps2_keyboard/
│   ├── grupo_F_ps2_mouse/
│   ├── grupo_G_nes_controller/
│   ├── grupo_H_i2c/
│   ├── grupo_I_i2s/
│   └── grupo_J_display/
├── software/
│   └── grupo_K_juegos/
│       ├── comun/                   — contratos compartidos (InterfazJuego, perifericos.h, etc.)
│       ├── pong/                    — entidades + diagramas + mockup de pantalla
│       ├── space_invaders/
│       ├── snake/
│       └── carrito/
└── mecanica/
    └── gabinete/                    — BOM, diagramas SVG y 6 sub-carpetas de decisión
```

## Documentos adicionales

Empezar por **[`docs/README.md`](docs/README.md)** — es el índice de
toda la documentación técnica del proyecto (arquitectura, mapa de
memoria, lógica de juegos, seguridad, y el registro de decisiones).

## Estado actual del proyecto

Ver **[`docs/decisiones_cerradas.md`](docs/decisiones_cerradas.md)**
para el registro completo — incluye lo que antes vivía aquí como
"preguntas abiertas" (la generación de 4 audios independientes y la
resolución compartida de las 4 pantallas ya están resueltas, ver ahí el
detalle) y todo lo que sigue pendiente.
