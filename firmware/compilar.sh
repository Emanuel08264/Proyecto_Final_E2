#!/bin/bash

# 1. Limpiar compilaciones anteriores
rm -f *.o *.elf *.bin *.txt

# 2. Ensamblar start.s (Arquitectura RV32I)
riscv64-unknown-elf-as -march=rv32i -mabi=ilp32 -o start.o start.s

# 3. Compilar main.c (Sin enlazar todavía)
riscv64-unknown-elf-gcc -c -march=rv32i -mabi=ilp32 -o main.o main.c

# 4. Enlazar todo con el script (Crear el ejecutable)
riscv64-unknown-elf-ld -m elf32lriscv -T link_script.ld -o firmware.elf start.o main.o

# 5. Extraer solo los binarios (Datos crudos)
riscv64-unknown-elf-objcopy -O binary firmware.elf firmware.bin

# 6. Formatear a Hexadecimal para VHDL (Elimina espacios y líneas vacías)
# -An: Sin direcciones
# -t x4: Salida en Hex de 4 bytes
# -w4: 4 bytes por línea
# tr -d ' ': Borra los espacios en blanco del margen
# sed '/^$/d': Borra las líneas vacías al final
od -An -t x4 -w4 -v firmware.bin | tr -d ' ' | sed '/^$/d' > ram_init_gpio.txt

echo "----------------------------------------"
echo "¡LISTO! Archivo ram_init_gpio.txt generado."
echo "Ahora copialo a tu carpeta src/"