# PROYECTO FINAL

## PROCESADOR RISC-V

### SANTILLÁN ATILIO EMANUEL

### INGENIERÍA ELECTRÓNICA

### 2025

---

## RESUMEN

---

## INTRODUCCIÓN

---

## DESARROLLO

### Conjunto de registros de la arquitectura RISC-V

### Conjunto de instrucciones RV32I

#### Instrucciones tipo R

Las instrucciones tipo R (register-type) usan 3 registros como operando, dos como fuente (rs1 y rs2) y uno de destino rd. Cada campo de registro ocupa 5 bits, permitiendo direccionar cualquiera de los 32 registros del banco (x0-x31). En lenguaje maquina, las instrucciones R tienen el siguiente formato (**Imagen_1**).

![r-type](/imagenes/r_type.png "Formato instrucciones R")

**Imagen_1** _Formato instrucciones R_

Los campos **funct7 (7 bits), funct3 (3 bits) y opcode (7 bits)** son llamados bits de control y especifican la operación exacta ejecutar. Por ejemplo, _add y sub_ comparten el mismo _opcode y funct3_, diferenciándose únicamente en el _funct7_.

Las instrucciones R incluyen operaciones aritméticas (add, sub), lógicas (and, or y xor) y desplazamientos (sll, srl y sra), sin utilizar valores inmediatos, solo datos contenidos en registros.

#### Instrucciones tipo I

Las instrucciones tipo I (immediate-type) usan 2 registros como operando (uno como fuente (rs1) y uno de destino rd) y un operando de valor inmediato de 12 bits. En lenguaje maquina, las instrucciones I tienen el siguiente formato (**Imagen_2**).

![i-type](/imagenes/i_type.png "Formato instrucciones I")

**Imagen_2** _Formato instrucciones I_

Las instrucciones I incluyen operaciones aritméticas (addi), lógicas (andi, ori y xori) y desplazamientos (slli, srli y srai), utilizando valores inmediatos. Para la mayoría de operaciones el campo inmediato representa un numero de 12 bits en complemento a 2, excepto para los desplazamientos. En esos casos, imm 4:0 es el desplazamiento de 5 bits sin signo a realizar, y los 7 bits superiores son 0, excepto en srai, donde imm10 vale 1.

#### Instrucciones tipo S

Las instrucciones tipo S (store-type) se utilizan para escribir datos desde un registro hacia la memoria. A diferencia de las instrucciones tipo R o I, este formato no posee un registro de destino (rd), ya que el objetivo es enviar información a la RAM y no guardar un resultado en el conjunto de registros.

En su lugar, utilizan dos registros fuente: _rs1_ (que contiene la dirección base de memoria) y _rs2_ (que contiene el dato a almacenar). Además, emplean un valor inmediato de 12 bits con signo (complemento a 2) que actúa como desplazamiento (offset).

En lenguaje máquina, las instrucciones S tienen el siguiente formato (**Imagen_3**).

![s-type](/imagenes/s_type.png "Formato instrucciones S")

**Imagen_3** _Formato instrucciones S_

Para mantener la posición de los campos rs1 y rs2 alineada con los otros formatos, el inmediato de 12 bits se divide en dos partes dentro de la instrucción.

El opcode para todas las instrucciones de almacenamiento es 0100011, y el campo funct3 determina el ancho del dato a guardar: sb (byte), sh (media palabra) o sw (palabra completa).

#### Instrucciones tipo B

Las instrucciones tipo B (branch-type) manejan los saltos condicionales (como beq, bne, blt). Estructuralmente son muy similares al tipo S: utilizan dos registros fuente (rs1 y rs2) que se comparan para decidir si se toma el salto o no, y un inmediato que indica el destino del salto.

En lenguaje máquina, las instrucciones B tienen el siguiente formato (**Imagen_4**).

![b-type](/imagenes/b_type.png "Formato instrucciones B")

**Imagen_4** _Formato instrucciones B_

La principal diferencia radica en la codificación del inmediato. En las instrucciones de salto, el inmediato representa un desplazamiento de 13 bits con signo. Sin embargo, como las instrucciones en RISC-V siempre están alineadas a direcciones pares, el bit menos significativo (bit 0) es siempre 0 y no se almacena en la instrucción. Esto permite codificar un rango efectivo de 13 bits usando solo 12 bits de espacio.

Además, los bits del inmediato se encuentran "desordenados" dentro de la instrucción (bit swizzling). Este reordenamiento aparente se realiza para que el bit de signo siempre ocupe la posición 31 (igual que en los tipos R, I y S) y para que los otros bits coincidan lo máximo posible con el formato S, simplificando así el hardware de decodificación.

#### Instrucciones tipo U

#### Instrucciones tipo J

---

## RESULTADOS

---

## CONCLUSIONES

---

## REFERENCIAS
