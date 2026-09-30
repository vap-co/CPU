OUTPUT_ARCH(riscv)
ENTRY(_start)

MEMORY
{
    IMEM (rx)  : ORIGIN = 0x00000000, LENGTH = 8K
    DMEM (rwx) : ORIGIN = 0x10000000, LENGTH = 8K
}

SECTIONS
{
    .text :
    {
        KEEP(*(.text.init))
        *(.text .text.*)
    } > IMEM

    .rodata :
    {
        *(.rodata .rodata.*)
    } > DMEM

    .data :
    {
        *(.data .data.*)
        *(.sdata .sdata.*)
    } > DMEM

    .bss (NOLOAD) :
    {
        __bss_start = .;
        *(.bss .bss.*)
        *(.sbss .sbss.*)
        *(COMMON)
        __bss_end = .;
    } > DMEM

    . = ALIGN(16);
    _end = .;
    _stack_top = ORIGIN(DMEM) + LENGTH(DMEM);
}
