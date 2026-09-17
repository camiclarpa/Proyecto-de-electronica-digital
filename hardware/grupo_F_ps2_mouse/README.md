# Grupo F — `perip_ps2mouse`

Controlador de mouse PS/2 (configuración/depuración del sistema).

> **Direcciones actualizadas 2026-09-16**: se confirmaron contra el
> mapa de memoria oficial del curso (antes eran un supuesto propio sin
> validar). Detalle en
> [`../../docs/decisiones_cerradas.md`](../../docs/decisiones_cerradas.md).

## Función en el proyecto

Igual que el teclado PS/2 del Grupo E: es para configuración/depuración
del sistema, no para jugar (eso lo hacen los controles NES del Grupo G).
Podría usarse, por ejemplo, para un menú de administración con cursor.

## Estructura de esta carpeta

```
grupo_F_ps2_mouse/
├── README.md                (este archivo)
├── diagramas/README.md      — trama PS/2, formato del paquete de 3 bytes
├── rtl/
│   ├── Makefile                — `make sim` para correr la prueba
│   ├── perip_ps2mouse.v         — módulo real (receptor + acumulador de paquete + registros)
│   └── perip_ps2mouse_TB.v      — testbench (genera un paquete PS/2 real de 3 bytes)
└── firmware/
    ├── ps2_mouse.h              — direcciones + macros de registro
    └── ps2_mouse.c               — `mouse_dato_nuevo`, `mouse_leer_status`, `mouse_leer_dx/dy`
```

## Protocolo real

Misma capa física que el teclado (`PS2_CLK`/`PS2_DATA`, colector
abierto, tramas de 11 bits con paridad impar — ver
[`diagramas/README.md`](diagramas/README.md) y
[`../grupo_E_ps2_keyboard/diagramas/README.md`](../grupo_E_ps2_keyboard/diagramas/README.md)),
pero el flujo de más alto nivel es distinto:

1. Al conectarse, el mouse manda `0xAA 0x00` (self-test OK + device ID).
2. Para activar el modo de reporte continuo (*stream mode*), la FPGA
   debe mandar el comando `0xF4` al mouse — esto requiere que el
   controlador también sepa **transmitir** hacia el mouse (el host
   toma el bus PS/2), no solo recibir. **Esta parte todavía no está
   implementada** en `perip_ps2mouse.v` (ver sección "Estado" más
   abajo) — el módulo actual asume que el mouse ya está en modo
   streaming.
3. Una vez activado, el mouse manda paquetes de **3 bytes** sin que se
   le pida, cada vez que se mueve o cambia un botón:
   - Byte 1: `[Y-overflow][X-overflow][Y-sign][X-sign][1][middle-btn][right-btn][left-btn]`
   - Byte 2: delta X (con signo, complemento a 2)
   - Byte 3: delta Y (con signo, complemento a 2)

`perip_ps2mouse.v` reutiliza el mismo receptor de bytes de 11 bits que
`perip_ps2kbd.v` del Grupo E (protocolo de trama PS/2 idéntico a nivel
de bits, incluido el sincronizador de doble flip-flop) — la diferencia
está en la capa de encima, que acumula 3 bytes en vez de interpretar
cada byte como scancode.

## Tabla de registros (CSR)

Offsets relativos a la base de este periférico. La base real y la
ventana completa están en
[`../../docs/mapa_memoria.md`](../../docs/mapa_memoria.md) — **oficial,
confirmada contra el repositorio del profesor** (antes era un supuesto
propio sin validar).

| Registro | Offset | R/W | Descripción |
|---|---|---|---|
| `MOUSE_STATUS` | `0x00` | R | byte de estado crudo (botones + signos + overflow) |
| `MOUSE_DX` | `0x04` | R | delta X con signo (extendido a 32 bits) |
| `MOUSE_DY` | `0x08` | R | delta Y con signo (extendido a 32 bits) |
| `MOUSE_VALID` | `0x0C` | R | bit0 = paquete nuevo disponible (se limpia al leer) |

Base oficial: **`0x00440000`** (ventana `0x440000`–`0x44FFFF`, 64KB).

## Integración en el SoC

`perip_ps2mouse` recibe **`addr` como offset local** (ya restada la
base `0x440000`) — el decodificador central del SoC es responsable de:
1. Comparar la dirección del CPU contra la ventana `0x440000–0x44FFFF`.
2. Generar `cs = 1` solo cuando la dirección cae en esa ventana.
3. Conectar `addr = direccion_cpu - 0x440000` al puerto `addr` del
   módulo (mismo patrón que usa `perip_uart` del Grupo B con su base
   `0x400000`).

## Simulación

```bash
cd rtl
make sim
```

Corre el testbench `perip_ps2mouse_TB.v`: genera un paquete PS/2 real
de 3 bytes sobre `ps2_clk`/`ps2_data` (simulando al mouse como maestro
del reloj) y verifica que `MOUSE_STATUS`/`MOUSE_DX`/`MOUSE_DY`/
`MOUSE_VALID` queden correctos, incluyendo el signo de `dx`/`dy`.

## API en C para el Grupo K

Ver [`firmware/ps2_mouse.h`](firmware/ps2_mouse.h) y
[`firmware/ps2_mouse.c`](firmware/ps2_mouse.c):

```c
int     mouse_dato_nuevo(void);   // consulta MOUSE_VALID
uint8_t mouse_leer_status(void);  // lee MOUSE_STATUS
int32_t mouse_leer_dx(void);      // lee MOUSE_DX (con signo)
int32_t mouse_leer_dy(void);      // lee MOUSE_DY (con signo)
```

Uso opcional/secundario — solo si el menú de administración lo
necesita. No es parte del gameplay de los 4 juegos.

## Errores comunes a evitar
- Olvidar mandar el comando `0xF4` al conectar — sin esto el mouse
  nunca manda paquetes por su cuenta (se queda "callado"). Esta lógica
  de transmisión **todavía no existe** en `perip_ps2mouse.v` — ver
  "Estado".
- Confundir el orden de los bits de signo (`status_byte[4]`=X-sign,
  `status_byte[5]`=Y-sign) con los bits de overflow — están en
  posiciones específicas del primer byte, no intercambiables.
- No sincronizar `ps2_clk`/`ps2_data` (metaestabilidad) — el módulo ya
  incluye el sincronizador de doble flip-flop internamente, igual que
  `perip_ps2kbd.v`.
- Usar la dirección ABSOLUTA (`0x440000 + offset`) dentro del propio
  módulo — el módulo solo debe conocer el offset; la base la maneja el
  decodificador central del SoC.

## Estado
- [x] Módulo diseñado (recepción de paquetes de 3 bytes)
- [x] Testbench escrito (`perip_ps2mouse_TB.v`)
- [ ] Módulo simulado y verificado (correr `make sim`)
- [ ] Módulo probado en hardware real (Colorlight 5A-75E)
- [ ] Comando de habilitación `0xF4` (TX de la FPGA hacia el mouse) — **no implementado**, pendiente
- [x] Mapa de registros documentado (offsets arriba, base oficial confirmada)
