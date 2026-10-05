ENTRY(_start)

MEMORY
{
    ROM (rx)  : ORIGIN = 0x00000000, LENGTH = 64K
    RAM (rwx) : ORIGIN = 0x20000000, LENGTH = 16K
}

SECTIONS
{
    .text : { KEEP(*(.text.init)) *(.text*) *(.rodata*) } > ROM
    .data : { *(.data*) } > RAM AT > ROM
    .bss  : { *(.bss*) *(COMMON) } > RAM

    _stack_top = ORIGIN(RAM) + LENGTH(RAM);
}
