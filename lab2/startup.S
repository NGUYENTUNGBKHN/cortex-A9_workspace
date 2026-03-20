/*
 * startup.S  —  ARM Cortex-A9 baremetal startup
 * DE10-Nano / Cyclone V HPS
 *
 * Responsibilities:
 *   1. Set SVC-mode stack pointer
 *   2. Copy .data from LMA → VMA  (LMA==VMA when running from DDR3)
 *   3. Zero .bss
 *   4. Call main()
 *   5. Hang in infinite loop if main() returns
 *
 * NOTE: U-Boot SPL has already:
 *   - Configured PLL / clocks
 *   - Trained and initialised DDR3
 *   - Set up basic pinmux
 * So we only need to set up the C runtime here.
 */

    .syntax unified
    .arch   armv7-a
    .cpu    cortex-a9

/* ------------------------------------------------------------------ */
/*  Vector table (placed first by linker script via .vectors section)  */
/* ------------------------------------------------------------------ */
    .section .vectors, "ax", %progbits
    .global _vectors
_vectors:
    ldr     pc, =_start             /* Reset                */
    ldr     pc, =hang               /* Undefined instruction */
    ldr     pc, =hang               /* SVC                  */
    ldr     pc, =hang               /* Prefetch abort       */
    ldr     pc, =hang               /* Data abort           */
    ldr     pc, =hang               /* Reserved             */
    ldr     pc, =hang               /* IRQ                  */
    ldr     pc, =hang               /* FIQ                  */

/* ------------------------------------------------------------------ */
/*  Reset entry point                                                   */
/* ------------------------------------------------------------------ */
    .section .text._start, "ax", %progbits
    .global _start
    .type   _start, %function
_start:

    /* ---- 1. Switch to SVC mode, disable IRQ/FIQ ---- */
    mrs     r0, cpsr
    bic     r0, r0, #0x1F           /* clear mode bits */
    orr     r0, r0, #0x13           /* SVC mode        */
    orr     r0, r0, #0xC0           /* disable IRQ+FIQ */
    msr     cpsr_c, r0

    /* ---- 2. Set up stack pointer ---- */
    ldr     sp, =_stack_top

    /* ---- 3. Invalidate caches & TLB (good practice) ---- */
    mov     r0, #0
    mcr     p15, 0, r0, c7,  c5, 0  /* Invalidate I-cache          */
    mcr     p15, 0, r0, c8,  c7, 0  /* Invalidate unified TLB      */
    mcr     p15, 0, r0, c7, c10, 4  /* DSB                         */
    mcr     p15, 0, r0, c7,  c5, 4  /* ISB                         */

    /* ---- 4. Copy .data section (LMA → VMA) ---- */
    /*   When running directly from DDR3, LMA == VMA so this loop   */
    /*   is a no-op. It is kept for correctness if you later XIP     */
    /*   from QSPI/NAND.                                              */
    ldr     r1, =_data_load         /* source (LMA)    */
    ldr     r2, =_data_start        /* dest   (VMA)    */
    ldr     r3, =_data_end
copy_data:
    cmp     r2, r3
    bge     copy_data_done
    ldr     r0, [r1], #4
    str     r0, [r2], #4
    b       copy_data
copy_data_done:

    /* ---- 5. Zero .bss section ---- */
    ldr     r2, =_bss_start
    ldr     r3, =_bss_end
    mov     r0, #0
zero_bss:
    cmp     r2, r3
    bge     zero_bss_done
    str     r0, [r2], #4
    b       zero_bss
zero_bss_done:

    /* ---- 6. Call main() ---- */
    mov     r0, #0                  /* argc = 0 */
    mov     r1, #0                  /* argv = NULL */
    bl      main

    /* ---- 7. Hang if main() returns (should never happen) ---- */
hang:
    wfe
    b       hang

    .size _start, . - _start
