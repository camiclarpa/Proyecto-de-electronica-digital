# Grupo J — display_driver.v

Controlador de las 4 salidas de video independientes.

## Función en el proyecto

Es el módulo que convierte lo que hay en el framebuffer de cada juego
en una señal de video real que la pantalla pueda mostrar. Es, junto con
el Grupo G (controles), el módulo más crítico para que el proyecto
"se vea" funcionando.

**✅ DECISIÓN CERRADA (2026-09-16): el FPGA genera VGA, no HDMI.**

Se evaluaron las dos opciones reales para la salida de video de las 4
pantallas:

| Opción | Qué requiere del FPGA | Riesgo real |
|---|---|---|
| **VGA (analógica)** ✅ ELEGIDA | Un contador de timing (ver `vga_timing` más abajo, ya escrito) + un DAC resistivo simple (2-4 resistencias por canal de color) en los pines de salida | Bajo — es el estándar que usan casi todos los cursos universitarios de "Pong/Tetris en FPGA", no necesita IP especial |
| **HDMI (digital, TMDS)** ❌ descartada | 4 transmisores TMDS reales (serializar cada canal a ~250 MHz, 10× el reloj de píxel) — el Colorlight 5A-75E no trae pines diferenciales pensados para esto, y el flujo 100% open-source (Yosys+Nextpnr+Trellis) tiene soporte mucho menos probado para SERDES de alta velocidad que las herramientas propietarias de Lattice | Alto — 4 instancias simultáneas de esto es un proyecto de I+D en sí mismo, no algo razonable en el tiempo del curso |

**Por qué se cierra en VGA:**
1. El código de timing (`vga_timing`, más abajo) y el mapa de memoria de
   framebuffers ya están escritos asumiendo VGA — cambiar a HDMI
   implicaría rehacer esta parte desde cero.
2. Generar 4 salidas HDMI reales requiere 4 serializadores TMDS de alta
   velocidad — un riesgo de proyecto innecesario para un curso, y sin
   garantía de que el toolchain open-source del curso lo soporte de
   forma confiable a tiempo.
3. **El problema de que la pantalla comprada (ELECROW, ver
   [`mecanica/gabinete/cotizacion_pantalla.md`](../../mecanica/gabinete/cotizacion_pantalla.md))
   solo tenga entrada HDIM se resuelve por fuera del FPGA**: con un
   convertidor activo VGA→HDMI (dispositivo real y barato, ver esa
   cotización), en vez de complicar el diseño de hardware del Grupo J.

Si en el futuro se cambia a pantallas TFT pequeñas por SPI/paralelo
(ej. tipo ILI9341), el protocolo cambiaría por completo — pero esa no
es la ruta elegida.

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

## Esqueleto de implementación (generador de timing VGA real)

```verilog
module vga_timing (
    input  wire clk_pixel, // 25 MHz real, desde PLL
    output reg  hsync, vsync,
    output reg  video_on,   // 1 cuando esta en la zona visible (no en blanking)
    output reg  [9:0] pixel_x,
    output reg  [9:0] pixel_y
);
    // Horizontal: 640 visibles + 16 front + 96 sync + 48 back = 800
    // Vertical:   480 visibles + 10 front +  2 sync + 33 back = 525
    reg [9:0] h_count = 0;
    reg [9:0] v_count = 0;

    always @(posedge clk_pixel) begin
        if (h_count == 799) begin h_count <= 0; v_count <= (v_count==524) ? 0 : v_count+1; end
        else h_count <= h_count + 1;

        hsync <= ~(h_count >= 656 && h_count < 752); // activo en bajo
        vsync <= ~(v_count >= 490 && v_count < 492); // activo en bajo
        video_on <= (h_count < 640) && (v_count < 480);
        pixel_x <= h_count;
        pixel_y <= v_count;
    end
endmodule
```

El módulo `display_driver.v` completo envuelve esto y además lee del
framebuffer correspondiente en `(pixel_x, pixel_y)` para sacar el color
real a mostrar en `r,g,b` cuando `video_on=1` (negro/apagado cuando
`video_on=0`, es decir, durante el blanking).

## API en C para el Grupo K

```c
// display.h — el CPU NO controla el timing (eso lo hace el hardware
// solo), solo escribe en el framebuffer correspondiente a su pantalla.
#define FB1_BASE 0x00090000
#define FB2_BASE 0x00094000
#define FB3_BASE 0x00098000
#define FB4_BASE 0x0009C000

void poner_pixel(unsigned int fb_base, int x, int y, int ancho, unsigned short color) {
    volatile unsigned short* fb = (volatile unsigned short*)fb_base;
    fb[y * ancho + x] = color;
}
```

## Errores comunes a evitar
- Sacar el reloj de píxel del reloj del sistema sin pasar por un PLL
  real — 25.175 MHz no es un divisor entero limpio de la mayoría de
  relojes de FPGA; hay que generarlo con el PLL de la ECP5 (como el
  ejemplo `pll/` del repo del curso), no con un contador simple.
- Actualizar el framebuffer a mitad de un frame que se está escaneando
  activamente → parpadeo/tearing visible. Si da tiempo en el proyecto,
  usar doble buffer (dibujar en uno mientras se muestra el otro).
- **Subestimar el tamaño del framebuffer** (ver la nota de arriba sobre
  460KB a resolución completa) — definir la resolución REAL de cada
  juego antes de escribir una sola línea de este módulo.

## Estado
- [ ] Módulo diseñado
- [ ] Módulo simulado (testbench)
- [ ] Módulo probado en hardware real (Colorlight 5A-75E)
- [ ] Mapa de registros/memoria documentado (ver arriba)
