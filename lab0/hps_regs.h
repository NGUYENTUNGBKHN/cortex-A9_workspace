/*
 * hps_regs.h — Cyclone V HPS Peripheral Register Map
 * DE10-Nano Baremetal
 *
 * Reference: Cyclone V HPS TRM (cv_5400A)
 */

#ifndef HPS_REGS_H
#define HPS_REGS_H

#include <stdint.h>

/* ═══════════════════════════════════════════════════════════
 Base Addresses
 ═══════════════════════════════════════════════════════════ */

/* UART0 (HPS) */
#define UART0_BASE          0xFFC02000UL
/* UART1 (HPS) */
#define UART1_BASE          0xFFC03000UL

/* GPIO (HPS) */
#define GPIO0_BASE          0xFF708000UL   /* HPS GPIO 0 (HPS_KEY, HPS_LED) */
#define GPIO1_BASE          0xFF709000UL
#define GPIO2_BASE          0xFF70A000UL

/* Timer SP0/SP1 (Synopsys DesignWare) */
#define TIMER_SP0_BASE      0xFFC08000UL
#define TIMER_SP1_BASE      0xFFC09000UL

/* GIC (ARM Generic Interrupt Controller) */
#define GIC_DIST_BASE       0xFFFED000UL
#define GIC_CPU_BASE        0xFFFEC100UL   /* CPU Interface offset from PERIPHBASE */

/* L3 Regs / AXI bridges */
#define HPS2FPGA_BASE       0xC0000000UL   /* HPS-to-FPGA AXI bridge */
#define LW_HPS2FPGA_BASE    0xFF200000UL   /* Lightweight HPS-to-FPGA AXI bridge */

/* ═══════════════════════════════════════════════════════════
 Macro Helpers
 ═══════════════════════════════════════════════════════════ */

#define REG32(addr)         (*(volatile uint32_t *)(addr))
#define BIT(n)              (1UL << (n))
#define SETBITS(r, m, v)    ((r) = (((r) & ~(m)) | ((v) & (m))))

/* ═══════════════════════════════════════════════════════════
 UART Register Offsets (16550-compatible)
 ═══════════════════════════════════════════════════════════ */
#define UART_RBR_THR        0x00   /* RX Buffer / TX Holding  */
#define UART_IER            0x04   /* Interrupt Enable        */
#define UART_IIR_FCR        0x08   /* Int. Identity / FIFO Ctrl */
#define UART_LCR            0x0C   /* Line Control            */
#define UART_MCR            0x10   /* Modem Control           */
#define UART_LSR            0x14   /* Line Status             */
#define UART_DLL            0x00   /* Divisor Latch Low  (DLAB=1) */
#define UART_DLH            0x04   /* Divisor Latch High (DLAB=1) */

#define UART_LSR_THRE       BIT(5) /* TX Holding Reg Empty    */
#define UART_LSR_DR         BIT(0) /* Data Ready              */
#define UART_LCR_DLAB       BIT(7) /* Divisor Latch Access    */
#define UART_LCR_8N1        0x03   /* 8-bit, no parity, 1 stop */

/* ═══════════════════════════════════════════════════════════
 GPIO Register Offsets (Synopsys DW APB GPIO)
 ═══════════════════════════════════════════════════════════ */
#define GPIO_SWPORTA_DR     0x00   /* Port A Data             */
#define GPIO_SWPORTA_DDR    0x04   /* Port A Direction (1=out)*/
#define GPIO_EXT_PORTA      0x50   /* Port A External (read)  */

/* DE10-Nano: HPS_LED = GPIO53 → GPIO1[24], HPS_KEY = GPIO54 → GPIO1[25] */
#define HPS_LED_BIT         BIT(24)
#define HPS_KEY_BIT         BIT(25)

/* ═══════════════════════════════════════════════════════════
 Timer Register Offsets (Synopsys DW APB Timer)
 ═══════════════════════════════════════════════════════════ */
#define TIMER_LOAD_COUNT    0x00
#define TIMER_CURRENT_VAL   0x04
#define TIMER_CONTROL       0x08
#define TIMER_EOI           0x0C   /* clears interrupt        */
#define TIMER_INT_STATUS    0x10

#define TIMER_CTRL_EN       BIT(0)
#define TIMER_CTRL_MODE     BIT(1) /* 0=free-run, 1=user-defined */
#define TIMER_CTRL_INT_MASK BIT(2) /* 1=masked                */

/* ═══════════════════════════════════════════════════════════
 GIC Distributor Register Offsets
 ═══════════════════════════════════════════════════════════ */
#define GICD_CTLR           0x000
#define GICD_ISENABLER(n)   (0x100 + ((n) * 4))
#define GICD_IPRIORITYR(n)  (0x400 + ((n) * 4))
#define GICD_ITARGETSR(n)   (0x800 + ((n) * 4))
#define GICD_ICFGR(n)       (0xC00 + ((n) * 4))

/* GIC CPU Interface Register Offsets */
#define GICC_CTLR           0x00
#define GICC_PMR            0x04   /* Priority Mask           */
#define GICC_BPR            0x08   /* Binary Point            */
#define GICC_IAR            0x0C   /* Interrupt Acknowledge   */
#define GICC_EOIR           0x10   /* End of Interrupt        */

/* Cyclone V HPS IRQ IDs (GIC SPI base = 32) */
#define IRQ_TIMER_SP0       201    /* SP Timer 0              */
#define IRQ_UART0           194    /* UART 0                  */

#endif /* HPS_REGS_H */
