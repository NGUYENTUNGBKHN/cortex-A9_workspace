/*
 * startup.S — ARM Cortex-A9 Bare-metal Startup
 * DE10-Nano HPS  (Cyclone V)
 *
 *  - Installs exception vectors
 *  - Sets up IRQ / SVC stacks
 *  - Copies .data, clears .bss
 *  - Jumps to main()
 */

    .syntax unified
    .arch   armv7-a
    .arm

/* ─────────────────────────────────────────────────────────────
   ARM Mode Bits
───────────────────────────────────────────────────────────── */
    .equ MODE_USR, 0x10
    .equ MODE_FIQ, 0x11
    .equ MODE_IRQ, 0x12
    .equ MODE_SVC, 0x13
    .equ MODE_ABT, 0x17
    .equ MODE_UND, 0x1B
    .equ MODE_SYS, 0x1F
    .equ I_BIT,    0x80   /* IRQ disable */
    .equ F_BIT,    0x40   /* FIQ disable */

/* ─────────────────────────────────────────────────────────────
   Exception Vector Table  (must be placed at 0x00000000)
───────────────────────────────────────────────────────────── */
    .section .vectors, "ax"
    .global _start

_start:
    ldr pc, =Reset_Handler          /* 0x00 Reset          */
    ldr pc, =Undef_Handler          /* 0x04 Undefined Instr*/
    ldr pc, =SVC_Handler            /* 0x08 SVC            */
    ldr pc, =PrefAbort_Handler      /* 0x0C Prefetch Abort  */
    ldr pc, =DataAbort_Handler      /* 0x10 Data Abort      */
    nop                             /* 0x14 Reserved        */
    ldr pc, =IRQ_Handler            /* 0x18 IRQ             */
    ldr pc, =FIQ_Handler            /* 0x1C FIQ             */

/* ─────────────────────────────────────────────────────────────
   Reset Handler
───────────────────────────────────────────────────────────── */
    .section .text.startup, "ax"
    .global Reset_Handler
    .func   Reset_Handler

Reset_Handler:

    /* 1. Disable IRQ/FIQ globally */
    cpsid   if

    /* 2. Switch to IRQ mode → set IRQ stack */
    msr     cpsr_c, #(MODE_IRQ | I_BIT | F_BIT)
    ldr     sp, =_irq_stack_top

    /* 3. Switch to SVC mode → set SVC stack */
    msr     cpsr_c, #(MODE_SVC | I_BIT | F_BIT)
    ldr     sp, =_stack_top

    /* 4. Copy .data section from LMA → VMA */
    ldr     r0, =_data_lma
    ldr     r1, =_data_start
    ldr     r2, =_data_end
    cmp     r1, r2
    beq     .zero_bss
.copy_data:
    ldr     r3, [r0], #4
    str     r3, [r1], #4
    cmp     r1, r2
    blt     .copy_data

    /* 5. Zero .bss section */
.zero_bss:
    ldr     r1, =_bss_start
    ldr     r2, =_bss_end
    mov     r3, #0
    cmp     r1, r2
    beq     .call_main
.clear_bss:
    str     r3, [r1], #4
    cmp     r1, r2
    blt     .clear_bss

    /* 6. Jump to C main() */
.call_main:
    bl      main

    /* 7. Hang if main returns */
.hang:
    wfi
    b       .hang

    .endfunc

/* ─────────────────────────────────────────────────────────────
   Weak Default Handlers
───────────────────────────────────────────────────────────── */
    .weak  Undef_Handler
    .weak  SVC_Handler
    .weak  PrefAbort_Handler
    .weak  DataAbort_Handler
    .weak  FIQ_Handler

Undef_Handler:
PrefAbort_Handler:
DataAbort_Handler:
FIQ_Handler:
    wfi
    b       .

/* IRQ Handler — calls C-level irq_dispatch() */
    .global IRQ_Handler
    .func   IRQ_Handler
IRQ_Handler:
    /* Save return address and SPSR onto IRQ stack */
    sub     lr, lr, #4
    srsdb   sp!, #0x12          /* Save LR_irq + SPSR_irq to IRQ stack (mode 0x12) */
    cps     #0x13               /* Switch to SVC mode to use SVC stack            */
    push    {r0-r12, lr}        /* Save caller-saved regs + SVC LR                */
    bl      irq_dispatch
    pop     {r0-r12, lr}        /* Restore regs                                   */
    rfeia   sp!                 /* Return From Exception: restore PC + CPSR       */
    .endfunc

SVC_Handler:
    movs    pc, lr

/* ─────────────────────────────────────────────────────────────
   IRQ Stack (1KB dedicated, after main stack)
───────────────────────────────────────────────────────────── */
    .section .bss
    .align  3
    .space  0x400            /* 1 KB IRQ stack */
_irq_stack_top:
