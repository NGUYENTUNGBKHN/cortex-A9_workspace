/*
 * main.c  —  DE10-Nano baremetal demo
 *
 * Blinks the HPS User LED (connected to HPS GPIO1[24], pin HPS_LED)
 * Uses direct register access — no HAL dependency.
 *
 * Cyclone V HPS GPIO base addresses:
 *   GPIO0  : 0xFF708000
 *   GPIO1  : 0xFF709000   <-- HPS_LED is here (bit 24)
 *   GPIO2  : 0xFF70A000
 */

#include <stdint.h>


/* ------------------------------------------------------------------ */
/*  Main                                                               */
/* ------------------------------------------------------------------ */

int main(void)
{


    uint32_t led_state = 0;

    while (1)
    {

    	led_state++;
        /* ~500 ms delay */
        // delay_loop(40000000UL);
    }

    return 0;   /* Never reached */
}
