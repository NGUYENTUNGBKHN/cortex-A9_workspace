/*
 * gic.h / gic.c — ARM GIC-400 Driver
 * DE10-Nano HPS (Cyclone V) Baremetal
 *
 * Supports:
 *   - GIC Distributor init (GICD)
 *   - GIC CPU Interface init (GICC)
 *   - Enable/disable individual SPI interrupts
 *   - Acknowledge & EOI helpers
 */

#ifndef GIC_H
#define GIC_H

#include <stdint.h>

typedef void (*irq_handler_t)(void);

void gic_init(void);
void gic_irq_enable(uint32_t irq_id);
void gic_irq_disable(uint32_t irq_id);
void gic_register(uint32_t irq_id, irq_handler_t handler);
uint32_t gic_acknowledge(void);
void gic_eoi(uint32_t irq_id);

/* Called from startup.S IRQ_Handler */
void irq_dispatch(void);

#endif /* GIC_H */
