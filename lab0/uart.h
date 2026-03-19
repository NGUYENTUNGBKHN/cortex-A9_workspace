/*
 * uart.h — UART0 Driver for DE10-Nano HPS Baremetal
 * 16550-compatible, polling mode
 *
 * Divisor = l4_clk_hz / (16 * baud)
 * Computed at compile time via macro to avoid __aeabi_uidiv dependency.
 *
 * Example:
 *   uart_init(UART0_BASE, UART_DIVISOR(25000000, 115200));
 */

#ifndef UART_H
#define UART_H

#include <stdint.h>

/* Compile-time divisor calculation — no runtime division needed */
#define UART_DIVISOR(clk_hz, baud)   ((clk_hz) / (16u * (baud)))

void    uart_init   (uint32_t base, uint32_t divisor);
void    uart_putc   (uint32_t base, char c);
void    uart_puts   (uint32_t base, const char *s);
int     uart_getc   (uint32_t base);
void    uart_printf (uint32_t base, const char *fmt, ...);

#endif /* UART_H */
