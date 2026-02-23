.section .text.startup
.globl _start

_start:
    la gp, __global_pointer$
    la sp, _stack_top
    la a0, __sbss_start
    la a1, __sbss_end
    call zero_init
    la a0, __bss_start
    la a1, __bss_end
    call zero_init
    la a0, __init_array_start
    la a1, __init_array_end
    call run_action_array
    call main
    la a0, __fini_array_start
    la a1, __fini_array_end
    call run_action_array
    j .
zero_init:
    beq a0, a1, zero_init_done
    sb x0, 0(a0)
    addi a0, a0, 1
    j zero_init
zero_init_done:
    ret
run_action_array:
    mv s1, ra
    mv s2, a0
    mv s3, a1
run_action_array_loop:
    beq s2, s3, run_action_array_done
    lw t0, 0(s2)
    beqz t0, skip_action
    jalr t0
skip_action:
    addi s2, s2, 4
    j run_action_array_loop
run_action_array_done:
    mv ra, s1
    ret