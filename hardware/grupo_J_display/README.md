# Grupo J — display_driver.v

Controlador de las 4 salidas de video independientes.

## Función en el proyecto

Es el módulo que convierte lo que hay en el framebuffer de cada juego
en una señal de video real que la pantalla pueda mostrar. Es, junto con
el Grupo G (controles), el módulo más crítico para que el proyecto
"se vea" funcionando.

**[SUPUESTO — confirmar con el equipo/profesor]**: se asume salida
**VGA** por ser el estándar más simple y documentado para proyectos de
FPGA de este tipo (es lo que usan casi todos los cursos universitarios
de "Pong/Tetris en FPGA"). Si en cambio se van a usar pantallas TFT
pequeñas por SPI/paralelo (ej. tipo ILI9341), el protocolo cambia por
completo — avisar apenas se defina el hardware real de pantalla.

## Protocolo real (asumiendo VGA, 640×480 @ 60 Hz — timing estándar industry)

| Parámetro | Horizontal | Vertical |
|---|---|---|
| Píxeles visibles | 640 | 480 |
| Front porch | 16 | 10 |
| Sync pulse | 96 | 2 |
| Back porch | 48 | 33 |
| Total | 800 | 525 |

Reloj de píxel: **25.175 MHz** (aprox. 25 MHz, generado con un PLL a
partir del reloj de la placa — el mismo tipo de PLL que ya usa la
carpeta `pll/` del ejemplo `from-blinker-to-riscv-bruno-levy` del
repositorio del curso). `HSYNC` y `VSYNC` activos en bajo en esta
resolución estándar; 3 salidas analógicas o digitales de color
(R, G, B).

Con **4 pantallas** se necesitan 4 instancias de este generador de
timing corriendo en paralelo (pueden compartir el mismo PLL de 25 MHz
si están sincronizadas, o tener cada una su propio contador si no).

## Interfaz esperada (puertos del módulo, por cada instancia/pantalla)

```verilog
module display_driver (
    input  wire clk_pixel,     // ~25 MHz
    output wire hsync, vsync,
    output wire [3:0] r, g, b, // ajustar ancho segun DAC/resistencias reales disponibles
    output wire [9:0] pixel_x,  // coordenada actual (para que el CPU sepa que dibujar)
    output wire [9:0] pixel_y,
    input  wire [11:0] pixel_color // color a mostrar en (pixel_x, pixel_y), desde el framebuffer
);
```

## Mapa de memoria (PROPUESTO — validar contra el decodificador real `chip_select.v`)

| Dirección | Nombre | Lectura/Escritura | Descripción |
|---|---|---|---|
| `0x00090000` – `0x00093FFF` | FB1 | R/W | Framebuffer Pantalla 1 (a dimensionar según resolución real usada por juego, probablemente menor a 640×480 para que quepa en memoria) |
| `0x00094000` – `0x00097FFF` | FB2 | R/W | Framebuffer Pantalla 2 |
| `0x00098000` – `0x0009BFFF` | FB3 | R/W | Framebuffer Pantalla 3 |
| `0x0009C000` – `0x0009FFFF` | FB4 | R/W | Framebuffer Pantalla 4 |

**Nota real importante**: un framebuffer de 640×480 a color completo
(ej. 12 bits/píxel) pesa ~460 KB — probablemente demasiado para BRAM
interna de la FPGA. Opciones reales: (a) usar una resolución mucho más
baja tipo los juegos retro reales (ej. 160×120 u otra bajada, ~28 KB a
12 bits, mucho más manejable), o (b) guardar el framebuffer en la
SPIRAM externa del Grupo C en vez de BRAM. **Definir esto es uno de los
primeros puntos de coordinación entre Grupo J, Grupo C y Grupo K.**

## Requisitos desde el software (Grupo K)
- Cada juego dibuja a baja resolución (sprites simples: paletas,
  pelota, invasores, la serpiente, el carrito) — no se necesita alta
  resolución para ninguno de los 4 juegos.
- El framebuffer se actualiza por software; el `display_driver` solo lo
  "escanea" continuamente para generar la señal de video (doble buffer
  si se quiere evitar parpadeo, a evaluar según recursos disponibles).

## Estado
- [ ] Módulo diseñado
- [ ] Módulo simulado (testbench)
- [ ] Módulo probado en hardware real (Colorlight 5A-75E)
- [ ] Mapa de registros/memoria documentado (ver arriba)
