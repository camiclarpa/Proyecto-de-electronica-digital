# Firmware — BRAM

Este módulo, a diferencia de los demás, **no tiene un driver C**
(`bram.h`/`bram.c`): es memoria de programa normal, mapeada de forma
transparente. El compilador de GCC para RV32I ya genera `LW`/`SW`/
`LB`/`SB` directo sobre estas direcciones porque el software la usa
como cualquier variable, arreglo o puntero de C — no como un
periférico con registros de control que haya que leer/escribir con
macros especiales.
