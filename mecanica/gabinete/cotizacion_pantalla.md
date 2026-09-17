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
- **Importante**: el conector VGA que asumió el diseño del Grupo J
  (`display_driver.v`) requiere el cable adicional específico
  mencionado por Waveshare — si van a usar HDMI en su lugar (más
  simple, viene incluido), el Grupo J necesita adaptar su salida de
  HDMI en vez de VGA. **Esto hay que decidirlo antes de que el Grupo J
  avance más en su diseño** — HDMI es una interfaz digital serial
  (TMDS) completamente distinta a VGA (analógica), no es un cambio
  trivial de última hora.

## Actualización al BOM principal

Reemplaza la fila de pantallas en [`README.md`](README.md) con este
precio real verificado en vez de la estimación anterior, una vez el
equipo confirme cuál de las dos opciones va a comprar.
