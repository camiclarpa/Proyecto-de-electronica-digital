#include "ps2_mouse.h"

int mouse_dato_nuevo(void) {
    return MOUSE_VALID_REG & 0x1u;
}

uint8_t mouse_leer_status(void) {
    return (uint8_t) (MOUSE_STATUS_REG & 0xFFu);
}

int32_t mouse_leer_dx(void) {
    return MOUSE_DX_REG;
}

int32_t mouse_leer_dy(void) {
    return MOUSE_DY_REG;
}
