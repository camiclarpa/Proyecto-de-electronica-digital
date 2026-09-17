# Montaje de las pantallas

Cómo fijar físicamente cada una de las 4 pantallas de 7" al panel
Superior del gabinete, de forma segura y sin dejar la placa electrónica
expuesta (requisito de seguridad infantil).

## Método recomendado: reutilizar la carcasa de fábrica

Las pantallas del tipo evaluado en
[`../cotizacion_pantalla.md`](../cotizacion_pantalla.md) (Waveshare o la
alternativa ELECROW) **ya vienen con su propia carcasa plástica**
(vidrio templado al frente, PCB protegida por dentro). Esto simplifica
mucho el montaje:

1. **No se retira la carcasa de fábrica.** Se mantiene completa —
   así la PCB y el panel LCD quedan protegidos por el propio
   fabricante, sin que el equipo tenga que diseñar esa protección desde
   cero.
2. Se corta en el panel Superior una **ventana rectangular** un poco
   más pequeña que el borde exterior de la carcasa (para que el marco
   de la carcasa quede apoyado sobre el MDF, no caiga hacia adentro).
3. La carcasa se atornilla **desde atrás** del panel Superior, usando
   los propios puntos de anclaje que trae la carcasa (la mayoría de
   estos productos ya vienen con agujeros de montaje o pestañas
   laterales para esto — verificar en el datasheet/manual del modelo
   final elegido).

## Por qué NO se recomienda desmontar la pantalla de su carcasa

Una alternativa más "elegante" visualmente es retirar la pantalla de su
caja y montarla detrás de una ventana de acrílico a ras — pero:
- Expone la PCB y el conector flex del panel LCD a manipulación directa
  (riesgo real de dañarlo, es frágil).
- Elimina la protección de vidrio templado que ya trae de fábrica.
- Es más difícil de lograr bien por un equipo que no lo ha hecho antes.

Dado el requisito de seguridad infantil y que esto es un primer
proyecto de este tipo para el equipo, **usar la carcasa de fábrica es
la opción correcta**, no solo la más fácil.

## Medidas a confirmar (dependen del modelo final)

| Medida | Por confirmar |
|---|---|
| Ancho × alto exterior de la carcasa | Ver datasheet del modelo elegido |
| Posición de los puntos de anclaje/tornillos | Ver datasheet del modelo elegido |
| Profundidad de la carcasa (afecta el espacio interno disponible para la repisa de la FPGA) | Ver datasheet del modelo elegido |

## Pendiente
- [ ] Conseguir el datasheet/manual exacto del modelo de pantalla que
  finalmente se compre, con sus medidas de carcasa reales
- [ ] Actualizar las coordenadas de corte en
  [`../plano_de_corte/README.md`](../plano_de_corte/README.md) con esas
  medidas exactas

## Integrantes responsables
-
