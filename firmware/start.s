.section .text.init
.global _start

_start:
    # Configura el Stack Pointer (sp) al final de la RAM (usando el mapa del linker)
    la sp, __stack_top
    
    # Salta a tu código C
    call main

loop:
    # Si main termina, se queda aquí en bucle infinito para no crashear
    j loop