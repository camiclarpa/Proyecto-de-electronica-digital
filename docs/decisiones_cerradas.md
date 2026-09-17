# Registro de decisiones del proyecto

Este documento existe para que cualquiera (equipo, profesor) pueda ver
**en un solo lugar y de un vistazo** qué está decidido, qué es un
supuesto de trabajo pendiente de confirmar, y qué sigue abierto —  sin
tener que leer los ~20 README del repositorio para reconstruir esa
historia. Cada fila enlaza al documento con la justificación técnica
completa.

## Cómo leer este registro

| Estado | Significado |
|---|---|
| ✅ **Cerrada** | Decisión técnica tomada por el Grupo K, con fecha y justificación documentada. No bloquea el avance. |
| ⚠️ **Adoptada (sin confirmar)** | El proyecto ya está construido asumiendo esto, pero falta que el equipo completo o el profesor lo confirmen formalmente. Cambiarlo después tiene costo de retrabajo. |
| 📝 **Recomendación aplicada** | Una recomendación técnica razonada ya incorporada al diseño, sin ser una decisión formal con fecha — se puede ajustar sin mayor costo. |
| 🎨 **Propuesta abierta** | No es una decisión técnica; requiere que el equipo elija (ej. nombre, colores). |

## Decisiones cerradas ✅

| # | Decisión | Fecha | Elegido | Alternativa descartada | Por qué | Detalle completo |
|---|---|---|---|---|---|---|
| 1 | Multiplexado de las 4 pantallas sobre un solo CPU | 2026-09-16 | **Opción A: round-robin cooperativo** (un solo hilo, cada juego avanza "un cuadro" por turno) | Opción B: 4 tareas con cambio de contexto real | El aislamiento de fallos que motivaba la Opción B ya se resuelve con estados de error por juego + watchdog de hardware; B requeriría escribir un scheduler real en ensamblador RISC-V sin aportar valor al alcance del curso | [`software/grupo_K_juegos/README.md`](../software/grupo_K_juegos/README.md#sobre-el-multiplexado-entre-las-4-pantallas) |
| 2 | Salida de video del Grupo J | 2026-09-16 | **VGA** (analógica) generada por el FPGA | HDMI (TMDS digital) | El código de timing y el mapa de framebuffers ya asumían VGA; generar 4 salidas HDMI reales requeriría serializadores de alta velocidad que el toolchain open-source del curso soporta mal. La pantalla final (HDMI-only) se resuelve con un convertidor VGA→HDMI externo, barato y real | [`hardware/grupo_J_display/README.md`](../hardware/grupo_J_display/README.md#función-en-el-proyecto) y [`mecanica/gabinete/cotizacion_pantalla.md`](../mecanica/gabinete/cotizacion_pantalla.md) |
| 3 | Altura del gabinete | 2026-09-16 | **75 cm**, uso de pie | 55 cm (uso sentado) | Los estándares de mobiliario escolar por estatura infantil, aplicados a un mueble de pie (no una mesa con silla), dan ~75cm como altura correcta para el rango de edad objetivo | [`mecanica/gabinete/ergonomia_infantil/README.md`](../mecanica/gabinete/ergonomia_infantil/README.md) |
| 4 | Disipación térmica del gabinete | 2026-09-16 | **1 ventilador 12V 40-60mm** con rejilla de protección | Convección pasiva únicamente (sin ventilador) | La estimación de consumo (~22W: 4 pantallas + FPGA + fuente) supera el límite práctico de convección pasiva en un gabinete de madera cerrado (~10-15W) | [`mecanica/gabinete/disipacion_termica/README.md`](../mecanica/gabinete/disipacion_termica/README.md) |

## Supuestos adoptados, sin confirmar formalmente ⚠️

Todo el proyecto ya está construido (hardware, mapa de memoria, mockups
de software) asumiendo estos dos puntos. **No son decisiones cerradas
del Grupo K** — son inconsistencias que existían en las notas
originales del equipo y que se resolvieron con un supuesto razonable
para poder avanzar, pendientes de que el equipo completo o el profesor
las confirmen.

| # | Supuesto adoptado | Alternativa descartada | Por qué se adoptó | Detalle |
|---|---|---|---|---|
| 5 | Los controles de juego usan protocolo **estilo NES** (shift register: clock + latch + data) | Protocolo PS/2 para los controles de juego | El Grupo G ya existe como `nes_controller.v` en la encuesta de grupos; PS/2 (Grupos E/F) se reserva para teclado/mouse de configuración y depuración del sistema, no para jugar | [`README.md`](../README.md#1-supuestos-que-hay-que-confirmar) |
| 6 | Son **8 controles físicos en total** (2 por cada una de las 4 pantallas) | 4 controles (1 por pantalla) | Permite multijugador local de hasta 2 jugadores por juego, consistente con Pong (2 jugadores) | [`README.md`](../README.md#1-supuestos-que-hay-que-confirmar) |

## Recomendaciones técnicas ya aplicadas 📝

| # | Recomendación | Por qué | Detalle |
|---|---|---|---|
| 7 | Montaje de pantallas: mantener la carcasa de fábrica, atornillada desde atrás del panel (no desmontar el panel LCD detrás de un acrílico) | Protege la PCB y el conector flex (frágil), conserva el vidrio templado de fábrica, más seguro para un equipo sin experiencia previa en esto | [`mecanica/gabinete/montaje_pantallas/README.md`](../mecanica/gabinete/montaje_pantallas/README.md) |

## Propuestas abiertas (no técnicas) 🎨

| # | Propuesta | Qué falta | Detalle |
|---|---|---|---|
| 8 | Identidad visual del producto (nombre, paleta de colores, método de aplicación) | El equipo elija/ajuste el nombre final y confirme si hay plotter de corte o impresora gran formato disponible en la universidad | [`mecanica/gabinete/identidad_visual/README.md`](../mecanica/gabinete/identidad_visual/README.md) |

## Preguntas originales del README ya resueltas

Estas dos preguntas estaban en la sección "Preguntas abiertas" del
`README.md` principal — ya tienen respuesta técnica real, documentada
en el README de su grupo de hardware correspondiente:

| # | Pregunta original | Respuesta | Detalle |
|---|---|---|---|
| 9 | ¿Cómo se generan 4 flujos de audio independientes desde un único I2S? | **4 instancias independientes** de `i2s_tx.v` (una por pantalla), no mezcla en software | [`hardware/grupo_I_i2s/README.md`](../hardware/grupo_I_i2s/README.md) |
| 10 | ¿Las 4 pantallas comparten resolución/refresco, o cada una es independiente? | Las 4 son **instancias independientes del mismo timing estándar** (VGA 640×480@60Hz) — mismo estándar, hardware desacoplado (si una falla, no afecta a las otras) | [`hardware/grupo_J_display/README.md`](../hardware/grupo_J_display/README.md) |

## Punto de coordinación activo (no es una decisión, es un riesgo técnico documentado)

**Tamaño del framebuffer (Grupo J ↔ Grupo C ↔ Grupo K)**: un
framebuffer de 640×480 a color completo pesa ~460 KB, probablemente
más de lo que cabe en BRAM interna de la FPGA. Ver el detalle y las dos
opciones reales (bajar resolución o usar la SPI RAM externa del Grupo
C) en [`hardware/grupo_J_display/README.md`](../hardware/grupo_J_display/README.md#mapa-de-memoria-propuesto--validar-contra-el-decodificador-real-chip_selectv).
Esto determina la resolución real de los 4 juegos, así que debe
resolverse antes de escribir el primer `.c` de cualquier juego.
