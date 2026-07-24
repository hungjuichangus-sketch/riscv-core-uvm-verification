# my_asm_test.S — hand-written RISC-V assembly, no C involved.
#
# crt0.S (dut/ibex/examples/sw/simple_system/common/crt0.S) has already
# run by the time we get here: registers are zeroed, .bss is cleared,
# the stack pointer is set up, and it calls us as `main` with the
# standard calling convention (jal x1, main). When `main` returns (ret),
# crt0 automatically halts the simulation -- no need to call sim_halt()
# yourself in assembly, though you could.
#
# puts/puthex/putchar (from simple_system_common.c, linked in
# automatically by common.mk) are available to call directly -- first
# argument goes in a0, per the standard RISC-V calling convention.

.section .data
test_msg:
    .asciz "My assembly memory test\n"

.section .bss
.align 2
scratch:
    .word 0            # one reserved, zero-initialized 32-bit word
scratch2:
    .word 0

.section .text
.global main

main:
    # main is a non-leaf function (it calls puts/puthex/putchar below),
    # each of which is a `call` that overwrites ra with its own return
    # address. Without saving/restoring our *own* incoming ra (set by
    # crt0's `jal x1, main`) around those nested calls, the final `ret`
    # below would jump into garbage instead of back into crt0's halt
    # sequence. This save/restore pair is what a C compiler generates
    # automatically for you -- in hand-written assembly you do it
    # yourself.
    addi sp, sp, -16
    sw   ra, 12(sp)

    # --- print a message ---
    la   a0, test_msg
    call puts

    # --- write a value to memory ---
    #la   t0, scratch       # t0 = address of our scratch word
    #li   t1, 0x1234ABCD    # t1 = value to store
    #sw   t1, 0(t0)         # mem[scratch] = 0x1234ABCD

    # --- read it back ---
    #lw   t2, 0(t0)         # t2 = mem[scratch]

    # --- print the result (puthex takes its argument in a0) ---
    #mv   a0, t2
    #call puthex
    #li   a0, '\n'
    #call putchar

    # ===================================================
    # Your own instructions go here. Ideas to try:
    #   - a byte store (sb) followed by a byte load (lb vs lbu --
    #     compare sign-extended vs zero-extended results)
    #   - two back-to-back stores to adjacent words
    #   - a load immediately followed by an add using the loaded
    #     value (the load-use hazard from TEST_PLAN.md Section 5.2)
    # ===================================================

    la   t0, scratch       # t0 = address of our scratch word
    addi a2, x0, 0xF2
    sb a2, 0(t0)
    lb a3, 0(t0)
    mv   a0, a3
    call puthex

    li a0, '\n'
    call putchar

    lbu a3, 0(t0)
    mv a0, a3
    call puthex

    li a0, '\n'
    call putchar

    li a2, 0xBEEF
    sh a2, 0(t0)
    lh a0, 0(t0)
    call puthex

    li a0, '\n'
    call putchar

    lhu a0, 0(t0)
    call puthex

    li a0, '\n'
    call putchar

    li a2, 0xDEADBEEF
    sw a2, 0(t0)
    lw a0, 0(t0)
    call puthex

    li a0, '\n'
    call putchar

    li a2, 0xDEADBEEF
    sw a2, 0(t0)
    lw a0, 1(t0)
    call puthex

    li a0, '\n'
    call putchar

    li a1, 0x11111111
    sw a1, 0(t0)
    la t1, scratch2
    li a2, 0x22222222
    sw a2, 0(t1)

    li a2, 0xDEADBEEF
    sw a2, 1(t0)
    lw a0, 0(t0)
    call puthex

    li a0, '\n'
    call putchar

    lw a0, 0(t1)
    call puthex

    li a0, '\n'
    call putchar
    
    lw   ra, 12(sp)
    addi sp, sp, 16
    ret     # crt0.S halts the simulation after main returns
