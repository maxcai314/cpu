OUTPUT_ARCH(riscv)

ENTRY(_start)

MEMORY_SIZE = 0x0F00;
STACK_SIZE = 0x0400;

MEMORY {
    ram (rwx) : ORIGIN = 0x00000000, LENGTH = 0x0F00
}

SECTIONS {
    /* Start at beginning of ram */
    . = ORIGIN(ram);

    .text : {
        *(.entry)
        *(.text)
        *(.text.*)
        *(.rodata)
        *(.rodata.*)
    } > ram

    .data : ALIGN(4) {
        *(.data)
        *(.data.*)
    } > ram

    .bss : ALIGN(4) {
        __bss_start = .;
        *(.bss)
        *(.bss.*)
        *(COMMON)
        __bss_end = .;
    } > ram

    /* End of program sections */
    _end = .;

    /* Stack at top of ram, growing down */
    .stack (NOLOAD) : {
        . = ALIGN(16);
        __stack_bottom = .;
        . = . + STACK_SIZE;
        . = ALIGN(16);
        __stack_top = .;
        _sp = __stack_top;
    } > ram
}
