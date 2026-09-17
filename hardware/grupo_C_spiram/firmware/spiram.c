#include "spiram.h"

// El acceso a esta memoria NO es instantaneo: cada lectura/escritura
// dispara una transaccion SPI real hacia el chip externo. El patron es:
//   1. Esperar a que termine cualquier transaccion previa (busy == 0).
//   2. Disparar la transaccion (el acceso mismo la inicia).
//   3. Esperar a que ESA transaccion termine (busy vuelve a 0).
//   4. Recien ahi el dato es valido (en lectura) o quedo escrito (en escritura).

uint32_t spiram_read(uint32_t offset) {
    while (SPIRAM_STATUS_REG & SPIRAM_STATUS_BUSY) {}
    (void) SPIRAM_DATA(offset);              // dispara la transaccion de lectura
    while (SPIRAM_STATUS_REG & SPIRAM_STATUS_BUSY) {}
    return SPIRAM_DATA(offset);              // ahora si, dato ya capturado
}

void spiram_write(uint32_t offset, uint32_t value) {
    while (SPIRAM_STATUS_REG & SPIRAM_STATUS_BUSY) {}
    SPIRAM_DATA(offset) = value;             // dispara la transaccion de escritura
}
