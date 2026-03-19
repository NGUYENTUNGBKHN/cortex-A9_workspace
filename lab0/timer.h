/*
 * timer.h — SP Timer Driver
 * DE10-Nano HPS Baremetal (Synopsys DesignWare APB Timer)
 */

#ifndef TIMER_H
#define TIMER_H

#include <stdint.h>

typedef void (*timer_cb_t)(void);

/* Initialize and start SP Timer 0 in periodic (user-defined) mode.
 * l4_sp_clk_hz : L4_SP clock in Hz  (typically 100 MHz post-bootloader)
 * period_ms     : Period in milliseconds
 * callback      : Function called on each timer interrupt
 */
void timer_init(uint32_t l4_sp_clk_hz, uint32_t period_ms, timer_cb_t callback);

/* Return elapsed milliseconds since timer_init() */
uint32_t timer_get_ms(void);

/* Internal: called by GIC dispatch */
void timer_isr(void);

#endif /* TIMER_H */
