OUTPUT_ARCH( "riscv" )
ENTRY( _start )

MEMORY
{
  /* RAM empieza en 0x00000000 y mide 2KB (512 palabras de 32 bits) */
  RAM (rwx) : ORIGIN = 0x00000000, LENGTH = 2K
}

SECTIONS
{
  . = 0x00000000; /* Le dice que empiece a escribir desde el principio */

  .text : {       /* .text es donde va el CÓDIGO */
    *(.text.init) /* Pone primero el código de arranque */
    *(.text)      /* Luego el resto del código */
  } > RAM

  .data : {       /* Variables inicializadas */
    *(.data)
  } > RAM
  
  /* Definimos dónde termina la RAM para poner el Stack allí */
  PROVIDE(__stack_top = ORIGIN(RAM) + LENGTH(RAM));
}