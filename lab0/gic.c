/*
 * gic.c — ARM GIC-400 Driver Implementation
 * DE10-Nano HPS Baremetal
 */

#include "gic.h"
#include "hps_regs.h"

#define MAX_IRQ     256
#define GICD(off)   REG32(GIC_DIST_BASE + (off))
#define GICC(off)   REG32(GIC_CPU_BASE  + (off))

/* ─── Handler Table ─────────────────────────────────────── */

static irq_handler_t irq_table[MAX_IRQ];

/* ─── GIC Init ──────────────────────────────────────────── */

void gic_init(void) {
	/* 1. Disable distributor */
	GICD(GICD_CTLR) = 0;

	/* 2. Set all IRQs to lowest priority (0xFF) */
	for (int i = 0; i < MAX_IRQ / 4; i++)
		GICD(GICD_IPRIORITYR(i)) = 0xFFFFFFFF;

	/* 3. Target all SPIs to CPU0 */
	for (int i = 8; i < MAX_IRQ / 4; i++) /* SPI starts at 32 → reg index 8 */
		GICD(GICD_ITARGETSR(i)) = 0x01010101;

	/* 4. Set all SPIs as level-sensitive */
	for (int i = 2; i < MAX_IRQ / 16; i++)
		GICD(GICD_ICFGR(i)) = 0;

	/* 5. Enable distributor */
	GICD(GICD_CTLR) = 1;

	/* 6. CPU Interface: allow all priority levels, enable */
	GICC(GICC_PMR) = 0xFF;
	GICC(GICC_BPR) = 0;
	GICC(GICC_CTLR) = 1;
}

/* ─── Register Handler ──────────────────────────────────── */

void gic_register(uint32_t irq_id, irq_handler_t handler) {
	if (irq_id < MAX_IRQ)
		irq_table[irq_id] = handler;
}

/* ─── Enable / Disable ──────────────────────────────────── */

void gic_irq_enable(uint32_t irq_id) {
	uint32_t reg = irq_id / 32;
	uint32_t bit = irq_id % 32;

	/* Set priority to 0xA0 (higher than PMR threshold 0xFF) */
	uint32_t pri_reg = irq_id / 4;
	uint32_t pri_shift = (irq_id % 4) * 8;
	GICD(GICD_IPRIORITYR(pri_reg)) = (GICD(GICD_IPRIORITYR(pri_reg))
			& ~(0xFFu << pri_shift)) | (0xA0u << pri_shift);

	GICD(GICD_ISENABLER(reg)) = BIT(bit);
}

void gic_irq_disable(uint32_t irq_id) {
	/* ICENABLER register = ISENABLER base + 0x180 offset */
	uint32_t reg = irq_id / 32;
	uint32_t bit = irq_id % 32;
	REG32(GIC_DIST_BASE + 0x180 + reg * 4) = BIT(bit);
}

/* ─── Acknowledge & EOI ─────────────────────────────────── */

uint32_t gic_acknowledge(void) {
	return GICC(GICC_IAR) & 0x3FF; /* bits[9:0] = IRQ ID */
}

void gic_eoi(uint32_t irq_id) {
	GICC(GICC_EOIR) = irq_id;
}

/* ─── Dispatch (called from IRQ_Handler in startup.S) ───── */

void irq_dispatch(void) {
	uint32_t irq_id = gic_acknowledge();

	if (irq_id < MAX_IRQ && irq_table[irq_id])
		irq_table[irq_id]();

	gic_eoi(irq_id);
}
