/*
 * Linker Script — DE10-Nano HPS Baremetal
 * Target  : Cyclone V HPS  ARM Cortex-A9
 * Toolchain: arm-none-eabi-gcc
 *
 * Memory Map (Cyclone V HPS Technical Reference Manual):
 *
 *   0xFFFF0000 - 0xFFFFFFFF  OCRAM  64 KB  (Boot / Baremetal)
 *   0x00000000 - 0x3FFFFFFF  SDRAM  up to 1 GB  (after DDR init)
 *   0xFF200000 - 0xFF3FFFFF  Lightweight HPS-to-FPGA AXI Bridge
 *   0xFF700000 - 0xFF7FFFFF  HPS Peripherals (UART, GPIO, Timer …)
 *
 * Stack layout inside OCRAM (top-down):
 *
 *   0xFFFFFFFF ┐
 *              │  SVC stack  (16 KB)   ← _stack_top   / _stack_bottom
 *   0xFFFFC000 ┤
 *              │  IRQ stack  ( 1 KB)   ← _irq_stack_top / _irq_stack_bottom
 *   0xFFFFBC00 ┘
 *
 * NOTE: _irq_stack_top is also defined as a label at the END of the
 *       1-KB .bss space reserved in startup.S  (.space 0x400).
 *       The linker symbols here must agree with that layout.
 */

ENTRY(_start)

/* ── Memory Regions ─────────────────────────────────────────────────────── */

MEMORY
{
    /*
     * OCRAM: 64 KB at 0xFFFF0000
     * Top 17 KB reserved for stacks:
     *   16 KB SVC  + 1 KB IRQ  = 17 KB  → code/data fits in lower 47 KB
     */
    OCRAM (rwx) : ORIGIN = 0xFFFF0000, LENGTH = 64K

    /* SDRAM: available after DDR init by preloader/U-Boot */
    SDRAM (rwx) : ORIGIN = 0x00000000, LENGTH = 512M
}

/* Alias for easy region swap (OCRAM ↔ SDRAM) */
REGION_ALIAS("REGION_TEXT",   OCRAM)
REGION_ALIAS("REGION_RODATA", OCRAM)
REGION_ALIAS("REGION_DATA",   OCRAM)
REGION_ALIAS("REGION_BSS",    OCRAM)

/* ── Stack Symbols (no section needed — pure address constants) ─────────── */
/*
 *  SVC stack  : top-most 16 KB of OCRAM
 *  IRQ stack  : next 1 KB below SVC stack
 *
 *  startup.S loads:
 *    sp  ← _stack_top      (SVC mode)
 *    sp  ← _irq_stack_top  (IRQ mode)
 */
_stack_top        = ORIGIN(OCRAM) + LENGTH(OCRAM);          /* 0xFFFFFFFF+1 = wraps to 0x00010000? No: sp is pre-decrement */
                                                              /* ARM uses full-descending stack: first push writes to sp-4   */
_stack_bottom     = _stack_top    - 0x4000;                 /* 0xFFFFC000  (16 KB SVC stack)  */

_irq_stack_top    = _stack_bottom;                          /* 0xFFFFC000  (IRQ stack grows down from here) */
_irq_stack_bottom = _irq_stack_top - 0x400;                 /* 0xFFFFBC00  (1 KB IRQ stack)   */

/* ── Sections ───────────────────────────────────────────────────────────── */

SECTIONS
{
    . = ORIGIN(OCRAM);      /* start at 0xFFFF0000 */

    /* ── Exception Vector Table ────────────────────────────────────────── */
    /*    Must be the very first bytes loaded (VBAR or boot address).       */
    .vectors :
    {
        KEEP(*(.vectors))
    } > REGION_TEXT

    /* ── Startup + Code ─────────────────────────────────────────────────── */
    .text :
    {
        *(.text.startup)    /* Reset_Handler first */
        *(.text*)
        . = ALIGN(4);
    } > REGION_TEXT

    /* ── Read-only data ─────────────────────────────────────────────────── */
    .rodata :
    {
        *(.rodata*)
        . = ALIGN(4);
    } > REGION_RODATA

    /* ── Initialized data ───────────────────────────────────────────────── */
    /*    LMA = load address (same region for OCRAM-only build)             */
    /*    VMA = runtime address                                              */
    _data_lma = LOADADDR(.data);
    .data :
    {
        _data_start = .;
        *(.data*)
        . = ALIGN(4);
        _data_end = .;
    } > REGION_DATA

    /* ── Zero-initialised data ──────────────────────────────────────────── */
    /*    Includes the 1-KB IRQ stack space declared in startup.S:          */
    /*      .section .bss / .space 0x400 / _irq_stack_top:                 */
    /*    The label _irq_stack_top in .bss points to the END of that space, */
    /*    which matches _irq_stack_top defined above only when the .bss     */
    /*    happens to land there — we use the linker symbol version instead  */
    /*    so startup.S's  ldr sp, =_irq_stack_top  uses OUR definition.    */
    .bss (NOLOAD) :
    {
        _bss_start = .;
        *(.bss*)
        *(COMMON)
        . = ALIGN(4);
        _bss_end = .;
    } > REGION_BSS

    _end = .;   /* end of all used OCRAM */

    /* ── Safety Checks ──────────────────────────────────────────────────── */
    ASSERT(_end <= _irq_stack_bottom,
        "ERROR: .bss/_end overflows into IRQ stack region!")

    ASSERT(_irq_stack_bottom >= _stack_bottom - 0x400,
        "ERROR: IRQ stack symbol mismatch!")

    /* Discard unused ARM unwinding tables (saves space) */
    /DISCARD/ :
    {
        *(.ARM.exidx*)
        *(.ARM.extab*)
    }
}
