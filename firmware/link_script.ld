/* Linker script para RISC-V RV32I con soporte para binarios C de GCC */
/* RAM interna: 2048 bytes (512 x 32 bits) desde 0x00000000 */

ENTRY(_start)

MEMORY
{
    RAM (rwx) : ORIGIN = 0x00000000, LENGTH = 2048
}

SECTIONS
{
    . = ORIGIN(RAM);

    /* Código y literales de solo lectura */
    .text : {
        KEEP(*(.text.startup))
        KEEP(*(.init))
        *(.text .text.*)
        *(.rodata .rodata.*)
        *(.srodata .srodata.*)
    } > RAM

    /* Arreglos de constructores/destructores de C */
    . = ALIGN(4);
    .init_array : {
        PROVIDE(__init_array_start = .);
        KEEP(*(.init_array .init_array.*))
        PROVIDE(__init_array_end = .);
    } > RAM

    . = ALIGN(4);
    .fini_array : {
        PROVIDE(__fini_array_start = .);
        KEEP(*(.fini_array .fini_array.*))
        PROVIDE(__fini_array_end = .);
    } > RAM

    /* Datos inicializados */
    . = ALIGN(4);
    .data : {
        PROVIDE(__data_start = .);
        *(.data .data.*)
        PROVIDE(__data_end = .);
    } > RAM

    /* Datos pequeños direccionados via gp */
    . = ALIGN(4);
    .sdata : {
        PROVIDE(__global_pointer$ = . + 0x800);
        PROVIDE(__sdata_start = .);
        *(.sdata .sdata.*)
        *(.sdata2 .sdata2.*)
        PROVIDE(__sdata_end = .);
    } > RAM

    /* BSS de datos pequeños */
    . = ALIGN(4);
    .sbss (NOLOAD) : {
        PROVIDE(__sbss_start = .);
        *(.sbss .sbss.*)
        *(.scommon)
        PROVIDE(__sbss_end = .);
    } > RAM

    /* BSS general */
    . = ALIGN(4);
    .bss (NOLOAD) : {
        PROVIDE(__bss_start = .);
        *(.bss .bss.*)
        *(COMMON)
        PROVIDE(__bss_end = .);
    } > RAM

    . = ALIGN(4);
    PROVIDE(__heap_start = .);

    /* Tope de pila al final de la RAM */
    _stack_top = ORIGIN(RAM) + LENGTH(RAM);
    PROVIDE(__stack_top = _stack_top);
}