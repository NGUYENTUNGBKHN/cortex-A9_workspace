/*
 * timer.c — SP Timer 0 Driver Implementation
 * DE10-Nano HPS Baremetal
 */

#include "timer.h"
#include "gic.h"
#include "hps_regs.h"

#define TIMER(off)  REG32(TIMER_SP0_BASE + (off))

static timer_cb_t _user_cb = 0;
static uint32_t _tick_ms = 0;
static volatile uint32_t _elapsed_ms = 0;

/* ─── ISR ───────────────────────────────────────────────── */

void timer_isr(void) {
	/* Clear interrupt by reading EOI register */
	(void) TIMER(TIMER_EOI);

	_elapsed_ms += _tick_ms;

	if (_user_cb)
		_user_cb();
}

/* ─── Init ──────────────────────────────────────────────── */

void timer_init(uint32_t l4_sp_clk_hz, uint32_t period_ms, timer_cb_t callback) {
	_user_cb = callback;
	_tick_ms = period_ms;

	uint32_t load = (l4_sp_clk_hz / 1000u) * period_ms - 1u;

	/* Stop timer */
	TIMER(TIMER_CONTROL) = 0;

	/* Load count */
	TIMER(TIMER_LOAD_COUNT) = load;

	/* User-defined mode, interrupt unmasked, enable */
	TIMER(TIMER_CONTROL) = TIMER_CTRL_MODE | TIMER_CTRL_EN;

	/* Register ISR in GIC */
	gic_register(IRQ_TIMER_SP0, timer_isr);
	gic_irq_enable(IRQ_TIMER_SP0);
}

/* ─── Get elapsed time ──────────────────────────────────── */

uint32_t timer_get_ms(void) {
	return _elapsed_ms;
}
