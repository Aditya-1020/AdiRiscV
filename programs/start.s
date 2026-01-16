.section .text.init
.global _start

_start:
    # Initialize stack pointer
    la sp, _stack_top
    
    # Initialize global pointer
    .option push
    .option norelax
    la gp, __global_pointer$
    .option pop
    
    # Clear BSS section (uninitialized data)
    la a0, _bss_start
    la a1, _bss_end
clear_bss:
    bgeu a0, a1, done_bss
    sw zero, 0(a0)
    addi a0, a0, 4
    j clear_bss
    
done_bss:
    # Call main
    call main
    
    # Infinite loop if main returns
end_loop:
    j end_loop
