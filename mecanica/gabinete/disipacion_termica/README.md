# Disipación térmica

Cálculo real de si la ventilación pasiva (rejillas) que ya se dibujó en
`vista_interna.svg` es suficiente, o si hace falta un ventilador activo.

## Estimado de calor generado dentro del gabinete

**[ESTIMADO — confirmar con datasheets reales una vez se elijan los
componentes finales]**:

| Componente | Cantidad | Consumo estimado c/u | Subtotal |
|---|---|---|---|
| Colorlight 5A-75E (FPGA ECP5 activa) | 1 | ~3 W | 3 W |
| Pantalla 7" con driver board (backlight LED) | 4 | ~4 W | 16 W |
| Pérdidas de la fuente de alimentación (eficiencia ~85%) | 1 | ~3 W | 3 W |
| **Total estimado** | | | **≈ 22 W** |

Estos números son estimados típicos para componentes de este tipo y
tamaño — **no son del datasheet exacto de los componentes finales**
(todavía no se ha comprado el modelo definitivo de pantalla). Antes de
construir, hay que sumar el consumo real que reporte el datasheet de
cada pantalla elegida.

## ¿Alcanza la ventilación pasiva?

Regla práctica real de diseño de gabinetes electrónicos: la convección
natural (aire que entra frío por rejillas bajas y sale caliente por
rejillas altas, sin ventilador) funciona razonablemente bien hasta
aproximadamente **10-15 W** en un gabinete de este tamaño (madera, que
no ayuda a disipar calor como lo haría un chasis metálico). Por encima
de eso, la temperatura interna empieza a subir de forma notoria,
especialmente si el gabinete está cerrado como exige la seguridad
infantil (ver `docs/manejo_errores_y_seguridad.md`).

**Conclusión real**: con ~22 W estimados, **superamos el límite cómodo
de ventilación pasiva**. Recomendación: agregar **al menos un
ventilador pequeño de 12V (40mm o 60mm, tipo cooler de PC)**, montado
para extraer aire caliente por la rejilla trasera.

## Impacto en el diseño existente

- El ventilador necesita alimentación (se toma de la misma fuente de
  12V que ya está en el BOM — no requiere una fuente adicional).
- El ventilador debe llevar **rejilla/malla de protección** en ambos
  lados (seguridad infantil: nada de aspas expuestas a un dedo).
- Añadir esto al BOM principal:

| Ítem nuevo para el BOM | Cantidad | Precio estimado (COP) |
|---|---|---|
| Ventilador 12V 40-60mm con rejilla de protección | 1 | ~$15.000–25.000 (estimado, no verificado en tienda) |

## ✅ DECISIÓN CERRADA (2026-09-16)

**Se agrega 1 ventilador de 12V (40-60mm) con rejilla de protección en
ambos lados**, montado en la rejilla trasera para extraer aire
caliente. Ya incluido en:
- [`../README.md`](../README.md) → BOM principal (fila nueva)
- [`../vista_interna.svg`](../vista_interna.svg) → símbolo del ventilador junto a la rejilla trasera

## Pendiente (ya no bloqueante, son verificaciones futuras)
- [ ] Confirmar consumo real (datasheet) de la pantalla final elegida
- [ ] Medir temperatura real dentro de un prototipo antes de dar por
  bueno el diseño (la teoría ayuda, pero la verificación real con un
  termómetro/cámara térmica es lo que confirma si alcanza)
- [ ] Verificar precio real del ventilador en tienda antes de comprar

## Integrantes responsables
-
