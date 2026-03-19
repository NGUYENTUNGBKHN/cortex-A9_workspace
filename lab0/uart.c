/*
 * uart.c — UART0 16550-compatible polling driver
 * DE10-Nano HPS Baremetal
 *
 * Zero runtime division/modulo — fully libgcc-free.
 */

#include "uart.h"
#include "hps_regs.h"
#include <stdarg.h>

/* ─── Init ─────────────────────────────────────────────── */

void uart_init(uint32_t base, uint32_t divisor)
{
    REG32(base + UART_IER)     = 0;
    REG32(base + UART_IIR_FCR) = 0x07;          /* enable + reset FIFOs */
    REG32(base + UART_LCR)     = UART_LCR_DLAB;
    REG32(base + UART_DLL)     = divisor & 0xFF;
    REG32(base + UART_DLH)     = (divisor >> 8) & 0xFF;
    REG32(base + UART_LCR)     = UART_LCR_8N1;
    REG32(base + UART_MCR)     = 0x03;
}

/* ─── TX ────────────────────────────────────────────────── */

void uart_putc(uint32_t base, char c)
{
    while (!(REG32(base + UART_LSR) & UART_LSR_THRE))
        ;
    REG32(base + UART_RBR_THR) = (uint32_t)c;
    if (c == '\n')
        uart_putc(base, '\r');
}

void uart_puts(uint32_t base, const char *s)
{
    while (*s)
        uart_putc(base, *s++);
}

/* ─── RX ────────────────────────────────────────────────── */

int uart_getc(uint32_t base)
{
    if (REG32(base + UART_LSR) & UART_LSR_DR)
        return (int)(REG32(base + UART_RBR_THR) & 0xFF);
    return -1;
}

/* ─── Integer → decimal string (NO division, NO modulo) ─────
 *
 * Uses a fixed powers-of-10 table + repeated subtraction.
 * Covers full uint32_t range (0 .. 4294967295, 10 digits).
 * ─────────────────────────────────────────────────────────── */

static const uint32_t _pow10[10] = {
    1000000000UL, 100000000UL, 10000000UL, 1000000UL,
    100000UL,     10000UL,     1000UL,     100UL,
    10UL,         1UL
};

static void _putdec(uint32_t base, uint32_t n, int width, char pad)
{
    char buf[10];
    int  digits = 0;

    for (int i = 0; i < 10; i++) {
        uint8_t d = 0;
        while (n >= _pow10[i]) { n -= _pow10[i]; d++; }
        if (d || digits || i == 9) {
            buf[digits++] = '0' + d;
        }
    }

    /* left-pad */
    for (int p = digits; p < width; p++) uart_putc(base, pad);
    for (int i = 0; i < digits; i++)     uart_putc(base, buf[i]);
}

/* ─── Integer → hex string ─────────────────────────────── */

static void _puthex(uint32_t base, uint32_t n)
{
    const char *d = "0123456789abcdef";
    uart_puts(base, "0x");
    int leading = 1;
    for (int s = 28; s >= 0; s -= 4) {
        uint32_t nibble = (n >> s) & 0xFUL;
        if (nibble || !leading || s == 0) {
            uart_putc(base, d[nibble]);
            leading = 0;
        }
    }
}

/* ─── Minimal printf ────────────────────────────────────── */

void uart_printf(uint32_t base, const char *fmt, ...)
{
    va_list ap;
    va_start(ap, fmt);
    while (*fmt) {
        if (*fmt != '%') { uart_putc(base, *fmt++); continue; }
        fmt++;
        char pad  = ' ';
        int  width = 0;
        if (*fmt == '0') { pad = '0'; fmt++; }
        while (*fmt >= '0' && *fmt <= '9') { width = width * 10 + (*fmt++ - '0'); }
        switch (*fmt) {
        case 'c': uart_putc(base, (char)va_arg(ap, int)); break;
        case 's': uart_puts(base, va_arg(ap, const char *)); break;
        case 'd': { int v = va_arg(ap, int);
                    if (v < 0) { uart_putc(base, '-'); v = -v; }
                    _putdec(base, (uint32_t)v, width, pad); break; }
        case 'u': _putdec(base, va_arg(ap, uint32_t), width, pad); break;
        case 'x':
        case 'X': _puthex(base, va_arg(ap, uint32_t)); break;
        case '%': uart_putc(base, '%'); break;
        default:  uart_putc(base, '%'); uart_putc(base, *fmt); break;
        }
        fmt++;
    }
    va_end(ap);
}
