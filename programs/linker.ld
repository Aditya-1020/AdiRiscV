OUTPUT_ARCH("riscv")
ENTRY(_start)

MEMORY {
    imem : ORIGIN = 0x00000000, LENGTH = 4K
    dmem : ORIGIN = 0x00001000, LENGTH = 4K
}

SECTIONS {
    .text : {
        *(.text.init)
        *(.text*)
    } > imem
    
    .rodata : {
        *(.rodata*)
    } > imem
    
    .data : {
        _data_start = .;
        *(.data*)
    } > dmem
    
    .bss : {
        _bss_start = .;
        *(.bss*)
        *(COMMON)
        _bss_end = .;
    } > dmem
    
    /* Stack at end of data memory */
    .stack : {
        . = ALIGN(16);
        . = . + 0x400; /* 1KB stack */
        _stack_top = .;
    } > dmem
    
    /* Global pointer for relaxation */
    __global_pointer$ = MIN(_data_start + 0x800, MAX(_data_start + 0x800, _bss_end - 0x800));
}
