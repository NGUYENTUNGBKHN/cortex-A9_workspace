/*
 * Linker script - DE10-Nano Baremetal App
 * Target : Cyclone V HPS (ARM Cortex-A9)
 * Run    : DDR3 @ 0x00100000 (after U-Boot SPL init)
 * Tool   : arm-none-eabi-ld
 */

OUTPUT_FORMAT("elf32-littlearm")
OUTPUT_ARCH(arm)
ENTRY(_start)

/* ------------------------------------------------------------------ */
/*  Memory map (Cyclone V HPS)                                         */
/*    DDR3   : 0x00000000 - 0x3FFFFFFF  (1 GB)                        */
/*    OCRAM  : 0xFFFF0000 - 0xFFFFFFFF  (64 KB)                       */
/*    Periph : 0xFF000000 - 0xFFEFFFFF                                 */
/* ------------------------------------------------------------------ */

MEMORY
{
    /*
     * App load address: 1 MB into DDR3.
     * SPL occupies ~0x00000000..0x000FFFFF region (stack + code).
     * Adjust LENGTH if your app grows large.
     */
    DDR3 (rwx) : ORIGIN = 0x00100000, LENGTH = 256M

    /* On-chip RAM — available even before DDR3 init.
       Not used by this app but listed for reference. */
    OCRAM (rwx) : ORIGIN = 0xFFFF0000, LENGTH = 64K
}

/* ------------------------------------------------------------------ */
/*  Stack size (placed at top of DDR3 window)                          */
/* ------------------------------------------------------------------ */
_stack_size = 0x8000;   /* 32 KB */

SECTIONS
{
    /* ---- Code + read-only data ------------------------------------ */
    .text : ALIGN(4)
    {
        KEEP(*(.vectors))       /* Exception / interrupt vectors first */
        *(.text._start)
        *(.text*)
        *(.rodata*)
        *(.glue_7)
        *(.glue_7t)
        . = ALIGN(4);
    } > DDR3

    /* ---- C++ init/fini arrays ------------------------------------- */
    .init_array : ALIGN(4)
    {
        PROVIDE_HIDDEN(__init_array_start = .);
        KEEP(*(SORT(.init_array.*)))
        KEEP(*(.init_array))
        PROVIDE_HIDDEN(__init_array_end = .);
    } > DDR3

    .fini_array : ALIGN(4)
    {
        PROVIDE_HIDDEN(__fini_array_start = .);
        KEEP(*(SORT(.fini_array.*)))
        KEEP(*(.fini_array))
        PROVIDE_HIDDEN(__fini_array_end = .);
    } > DDR3

    /* ---- Initialized data (LMA in flash/ROM, VMA in DDR3) --------- */
    /* Since we run from DDR3 directly, LMA == VMA here.               */
    _data_load = LOADADDR(.data);

    .data : ALIGN(4)
    {
        _data_start = .;
        *(.data*)
        . = ALIGN(4);
        _data_end = .;
    } > DDR3

    /* ---- Zero-initialized data ------------------------------------ */
    .bss : ALIGN(4)
    {
        _bss_start = .;
        *(.bss*)
        *(COMMON)
        . = ALIGN(4);
        _bss_end = .;
    } > DDR3

    /* ---- Stack ---------------------------------------------------- */
    .stack (NOLOAD) : ALIGN(8)
    {
        _stack_bottom = .;
        . = . + _stack_size;
        _stack_top = .;         /* SP initialized here in startup.S   */
    } > DDR3
	_heap_size = 0x100;
    /* ---- Heap (everything left) ----------------------------------- */
    .heap (NOLOAD) : ALIGN(8)
	{
	    _heap_start = .;
	    . = . + _heap_size; 
	    _heap_end = .;
	} > DDR3

    /* ---- Discard -------------------------------------------------- */
    /DISCARD/ :
    {
        *(.ARM.exidx*)
        *(.ARM.extab*)
        *(.comment)
        *(.note*)
    }
}
