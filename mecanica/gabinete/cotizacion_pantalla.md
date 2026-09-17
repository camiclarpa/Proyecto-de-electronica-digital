# Cotización real: pantalla Waveshare 7" HDMI LCD (H)

## Producto evaluado

**Waveshare 7inch HDMI LCD (H)** — 1024×600, IPS, panel táctil
capacitivo, entrada **HDMI y VGA** (VGA requiere un cable adicional,
vendido por separado), incluye caja/case, cable HDMI, adaptador HDMI a
Micro-HDMI y cable USB (para el touch).

## Precio real verificado

| Fuente | Precio | Nota |
|---|---|---|
| **Waveshare (oficial, waveshare.com)** | **US$47.99** | ✅ Verificado directo en la página oficial del fabricante, hoy |
| Amazon.com (listado en pesos para Colombia) | — | ⚠️ **Este producto exacto NO se puede enviar a Colombia** ("No puede enviarse este producto al punto de entrega seleccionado") — confirmado real al intentar comprarlo |
| MercadoLibre Colombia | — | Existe el listado ("Pantalla Lcd Waveshare 7 Pulgadas Hdmi 1024x600 Ips Touch"), pero requiere iniciar sesión para ver el precio — revisar directo: [enlace](https://articulo.mercadolibre.com.co/MCO-2739081230-pantalla-lcd-waveshare-7-pulgadas-hdmi-1024x600-ips-touch-_JM) |

## Alternativa real que SÍ llega a Colombia (mismo uso, especificación equivalente)

Mientras se consigue el Waveshare puntual, Amazon sí mostró esta
alternativa **funcionalmente equivalente** (7", 1024×600, IPS, touch
capacitivo, para Raspberry Pi/PC) con envío real a Colombia:

| Producto | Precio real (COP) |
|---|---|
| **ELECROW 7" 1024×600 IPS táctil capacitiva** | **$129.012,63 COP** ✅ (precio real visto en Amazon Colombia, hoy) |

## Recomendación

Para las **4 pantallas** del proyecto:
- Si compran por MercadoLibre Colombia el Waveshare (revisar precio real
  iniciando sesión): 4 × precio_ML
- Si usan la alternativa ELECROW confirmada: **4 × $129.013 ≈ $516.052 COP**

## ✅ DECISIÓN CERRADA (2026-09-16): HDMI vs VGA

El Grupo J genera **VGA** desde el FPGA (ver la justificación completa
en
[`hardware/grupo_J_display/README.md`](../../hardware/grupo_J_display/README.md#función-en-el-proyecto)) —
más simple y de bajo riesgo con el toolchain 100% open-source del
curso, comparado con generar 4 salidas HDMI/TMDS reales.

Esto significa que **cada pantalla necesita un convertidor VGA→HDMI**
si el modelo final comprado (Waveshare o ELECROW) solo acepta HDMI. Es
un producto real, barato y de venta común:

| Producto | Precio real (COP) |
|---|---|
| **Convertidor activo VGA a HDMI** (MercadoLibre Colombia) | **desde $17.850 COP** ✅ (visto en listado real de MercadoLibre Colombia, hoy) |

Para las 4 pantallas: **4 × ~$17.850 ≈ $71.400 COP** adicionales al BOM
(actualizar la fila de BOM en
[`README.md`](README.md) para incluirlo).

**Nota**: si al final se consigue el Waveshare puntual (que sí acepta
VGA nativo con el cable adicional que menciona el fabricante), el
convertidor no seria necesario para esas unidades — pero como la
alternativa confirmada que sí llega a Colombia (ELECROW) se vende
orientada a HDMI, se deja presupuestado el convertidor por pantalla
como caso general.

## Actualización al BOM principal

Reemplaza la fila de pantallas en [`README.md`](README.md) con este
precio real verificado en vez de la estimación anterior, una vez el
equipo confirme cuál de las dos opciones va a comprar.
