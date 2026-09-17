#include "ps2_keyboard.h"

int kbd_tecla_disponible(void) {
    return KBD_STATUS_REG & KBD_STATUS_VALID;
}

unsigned char kbd_leer_scancode(void) {
    return (unsigned char) (KBD_DATA_REG & 0xFFu);
}

int kbd_fue_soltada(void) {
    return (KBD_DATA_REG & KBD_DATA_RELEASE_BIT) != 0;
}
