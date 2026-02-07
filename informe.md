# PROYECTO FINAL

## PROCESADOR RISC-V

### SANTILLÁN ATILIO EMANUEL

### INGENIERÍA ELECTRÓNICA

### 2025

---

## RESUMEN

---

## INTRODUCCIÓN

### Arquitectura de computadora

El término "arquitectura de computadora" (o ISA - Instruction Set Architecture) se refiere a la visión abstracta del sistema desde la perspectiva del programador. Define la interfaz entre el hardware y el software, especificando los tipos de datos soportados, el conjunto de registros, los modos de direccionamiento y el conjunto de instrucciones disponibles, sin entrar en detalles de cómo estos se implementan físicamente (lo cual corresponde a la microarquitectura).

### Microarquitectura

La microarquitectura de computadoras incluye todo el hardware involucrado en el funcionamiento de una computadora. Esta definida por le arreglo de registros, memorias, unidades aritmético-lógicas (ALUs), y otro bloques constructivos del microprocesador.
La microarquitectura se divide en 2 partes que interactúan entre si: el datapath y la unidad de control. El datapath contiene las memorias, ALUs, registros y multiplexores. Como trabajamos con RV32I, el datapath es de 32 bits. La unidad de control recibe la instrucción actual y le indica al datapath como ejecutarla.
Para el diseño de una microarquitectura, primero deben definirse los elementos de estado. Nos centraremos en 4 elementos de estado: el program counter (PC), el register file, memoria de instrucción y memoria de información.

<u>Program counter:</u> es un puntero a la dirección de instrucción actual. Su entrada (PCNext) indica la dirección de la siguiente instrucción.

<u>Memoria de instrucción:</u> es una memoria simple de solo lectura. Toma la dirección de 32 bits proporcionada por PC y lee la instrucción que contiene (de 32 bits también).

<u>Conjunto de registros:</u> es una memoria multi puerto de 32x32 bits. Tiene dos puertos de lectura A1 Y A2, uno de escritura A3 de 5 bits (pues hay solo 32 registros). Ademas cuenta con una entrada de datos de 32 bits WD, y cuenta con habilitación de escritura WE sincrónica. La salida de lectura es de 32 bits.

<u>Memoria de datos:</u> memoria de lectura escritura con habilitación de escritura sincrónica. Las direcciones A, y las palabras a escribir WD o leer RD son de 32 bits.

En la **Imagen_2** se observa el símbolo de estos elementos.

![state_elements](/imagenes/state_elements.png "State elements")

**Imagen_2** *Elementos de estado*

#### Tipos de Microarquitectura RISC-V

Existen diversas formas de conectar los elementos de estado y la lógica para implementar el conjunto de instrucciones RISC-V. Las tres variantes principales son:

**Procesador Uniciclo (Single-Cycle):** Ejecuta la instrucción completa en un único ciclo de reloj. Aunque su lógica de control es simple y no requiere registros intermedios, tiene dos grandes desventajas: el periodo del reloj está limitado por la instrucción más lenta (como lw), y requiere memorias separadas para instrucciones y datos, lo cual es costoso y poco realista para sistemas simples.

**Procesador Segmentado (Pipelined):** Divide la ejecución en varias etapas que funcionan en paralelo (como una línea de montaje), permitiendo ejecutar múltiples instrucciones simultáneamente. Esto mejora drásticamente el rendimiento (throughput), pero requiere hardware adicional para gestionar dependencias de datos y registros de segmentación. Es el estándar en procesadores comerciales modernos.

**Procesador Multiciclo (Multicycle):** Esta arquitectura ejecuta una instrucción a lo largo de una serie de ciclos más cortos. Sus ventajas principales, y la razón por la que se implementará en este proyecto, son:

- Reutilización de Hardware: Permite usar unidades costosas (como la ALU o sumadores) varias veces dentro de la misma instrucción para distintos propósitos.

- Memoria Única: A diferencia del uniciclo, puede utilizar una sola interfaz de memoria tanto para leer instrucciones (fetch) como para leer/escribir datos, accediendo a ella en ciclos diferentes.

- Eficiencia: Las instrucciones simples toman menos ciclos que las complejas.

Para implementar este diseño, el datapath debe incorporar elementos de estado no arquitectónicos adicionales para almacenar los resultados intermedios entre cada paso. Asimismo, dado que se generan señales de control diferentes en cada paso de una misma instrucción, el controlador debe implementarse mediante una Máquina de Estados Finitos (FSM) en lugar de lógica combinacional pura.

---

## DESARROLLO

### Arquitectura RISC-V 

La arquitectura RISC-V se introduce como la primera arquitectura de conjunto de instrucciones (ISA) de código abierto que cuenta con un amplio soporte comercial. Fue definida inicialmente en el año 2010 en la Universidad de California, Berkeley, por Krste Asanović, Andrew Waterman y David Patterson, entre otros.

Una característica inusual de RISC-V es que su naturaleza de código abierto la hace de uso gratuito, manteniendo capacidades comparables a arquitecturas comerciales establecidas como ARM y x86. El diseño de esta arquitectura se basó en cuatro principios fundamentales: (1) la regularidad apoya la simplicidad; (2) hacer rápido el caso común; (3) lo más pequeño es más rápido; y (4) el buen diseño exige buenos compromisos.

Con respecto al RV32I, se describe como el conjunto de instrucciones de enteros de 32 bits (versión 2.2). Este conjunto es fundamental, ya que forma el núcleo (core) del conjunto de instrucciones de RISC-V.

### Conjunto de registros de la arquitectura RISC-V

La arquitectura RISC-V cuenta con 32 registros (ancho de palabra de 32 bits) llamada register set, almacenados en una pequeña memoria multi puerto llamada register file. Al tener pocos registros se obtiene una gran velocidad de acceso. Estos registros están numerados del 0 al 31 y tienen nombres y propósitos específicos. En la **Imagen_1** se observa la distribución de los registros:

![register_set](/imagenes/register_set.png "Register set")

**Imagen_1** *Conjunto de registros RISC-V*

Aunque la mayoría de registros son de propósito general, la arquitectura impone funciones específicas en hardware y convenciones de software (ABI) para algunos de ellos:

x0 (Zero): Este registro está cableado permanentemente al valor 0. Cualquier escritura en él es ignorada y cualquier lectura devuelve siempre 0. Esto simplifica el conjunto de instrucciones (por ejemplo, para mover datos se usa una suma con 0).

x1 (ra): Por convención, actúa como el Return Address Register, almacenando la dirección de retorno al llamar a subrutinas.

x2 (sp): Actúa como Stack Pointer (puntero de pila).

### Conjunto de instrucciones RV32I

#### Instrucciones tipo R

Las instrucciones tipo R (register-type) usan 3 registros como operando, dos como fuente (rs1 y rs2) y uno de destino rd. Cada campo de registro ocupa 5 bits, permitiendo direccionar cualquiera de los 32 registros del banco (x0-x31). En lenguaje maquina, las instrucciones R tienen el siguiente formato (**Imagen_1**).

![r-type](/imagenes/r_type.png "Formato instrucciones R")

**Imagen_1** *Formato instrucciones R*

Los campos **funct7 (7 bits), funct3 (3 bits) y opcode (7 bits)** son llamados bits de control y especifican la operación exacta ejecutar. Por ejemplo, _add y sub_ comparten el mismo _opcode y funct3_, diferenciándose únicamente en el _funct7_.

Las instrucciones R incluyen operaciones aritméticas (add, sub), lógicas (and, or y xor) y desplazamientos (sll, srl y sra), sin utilizar valores inmediatos, solo datos contenidos en registros.

#### Instrucciones tipo I

Las instrucciones tipo I (immediate-type) usan 2 registros como operando (uno como fuente (rs1) y uno de destino rd) y un operando de valor inmediato de 12 bits. En lenguaje maquina, las instrucciones I tienen el siguiente formato (**Imagen_2**).

![i-type](/imagenes/i_type.png "Formato instrucciones I")

**Imagen_2** *Formato instrucciones I*

Las instrucciones I incluyen operaciones aritméticas (addi), lógicas (andi, ori y xori) y desplazamientos (slli, srli y srai), utilizando valores inmediatos. Para la mayoría de operaciones el campo inmediato representa un numero de 12 bits en complemento a 2, excepto para los desplazamientos. En esos casos, imm 4:0 es el desplazamiento de 5 bits sin signo a realizar, y los 7 bits superiores son 0, excepto en srai, donde imm10 vale 1.

#### Instrucciones tipo S

Las instrucciones tipo S (store-type) se utilizan para escribir datos desde un registro hacia la memoria. A diferencia de las instrucciones tipo R o I, este formato no posee un registro de destino (rd), ya que el objetivo es enviar información a la RAM y no guardar un resultado en el conjunto de registros.

En su lugar, utilizan dos registros fuente: _rs1_ (que contiene la dirección base de memoria) y _rs2_ (que contiene el dato a almacenar). Además, emplean un valor inmediato de 12 bits con signo (complemento a 2) que actúa como desplazamiento (offset).

En lenguaje máquina, las instrucciones S tienen el siguiente formato (**Imagen_3**).

![s-type](/imagenes/s_type.png "Formato instrucciones S")

**Imagen_3** *Formato instrucciones S*

Para mantener la posición de los campos rs1 y rs2 alineada con los otros formatos, el inmediato de 12 bits se divide en dos partes dentro de la instrucción.

El opcode para todas las instrucciones de almacenamiento es 0100011, y el campo funct3 determina el ancho del dato a guardar: sb (byte), sh (media palabra) o sw (palabra completa).

#### Instrucciones tipo B

Las instrucciones tipo B (branch-type) manejan los saltos condicionales (como beq, bne, blt). Estructuralmente son muy similares al tipo S: utilizan dos registros fuente (rs1 y rs2) que se comparan para decidir si se toma el salto o no, y un inmediato que indica el destino del salto.

En lenguaje máquina, las instrucciones B tienen el siguiente formato (**Imagen_4**).

![b-type](/imagenes/b_type.png "Formato instrucciones B")

**Imagen_4** *Formato instrucciones B*

La principal diferencia radica en la codificación del inmediato. En las instrucciones de salto, el inmediato representa un desplazamiento de 13 bits con signo. Sin embargo, como las instrucciones en RISC-V siempre están alineadas a direcciones pares, el bit menos significativo (bit 0) es siempre 0 y no se almacena en la instrucción. Esto permite codificar un rango efectivo de 13 bits usando solo 12 bits de espacio.

Además, los bits del inmediato se encuentran "desordenados" dentro de la instrucción (bit swizzling). Este re ordenamiento aparente se realiza para que el bit de signo siempre ocupe la posición 31 (igual que en los tipos R, I y S) y para que los otros bits coincidan lo máximo posible con el formato S, simplificando así el hardware de decodificación.

#### Instrucciones tipo U

Las instrucciones tipo U (*upper immediate*) poseen un operando de registro de destino rd, un campo inmediato de 20 bits y un opcode de 7 bits. Los bits restantes especifican los 20 bits más significativos de un inmediato de 32 bits.

En lenguaje máquina, las instrucciones U tienen el siguiente formato (**Imagen_5**).

![u-type](/imagenes/u_type.png "Formato instrucciones U")

**Imagen_5** *Formato instrucciones U*

La instrucción lui (*load upper *immediate) es un ejemplo de este formato. El inmediato de 32 bits resultante consiste en los 20 bits superiores codificados en la instrucción y ceros en los bits inferiores. Por ejemplo, tras la ejecución, el registro de destino podría contener un valor como 0x8CDEF000 donde la parte alta proviene del inmediato.
Además de lui, existe la instrucción auipc (Add Upper Immediate to PC). Esta suma el inmediato de 20 bits (desplazado 12 bits a la izquierda) al PC actual. Sirve para generar direcciones de memoria relativas a la posición actual.

#### Instrucciones tipo J

Las instrucciones tipo J también poseen un registro de destino rd y un campo inmediato de 20 bits, pero en este caso, dichos bits especifican los 20 bits más significativos de un desplazamiento de salto (jump offset) de 21 bits.

En lenguaje máquina, las instrucciones J tienen el siguiente formato (**Imagen_6**).

![j-type](/imagenes/j_type.png "Formato instrucciones J")

**Imagen_6** *Formato instrucciones J*

Al igual que en las instrucciones tipo B, el bit menos significativo del inmediato es siempre 0 y no se codifica en la instrucción. Los bits restantes se encuentran mezclados (swizzled) dentro del campo inmediato de 20 bits.

La instrucción jal (*jump and link*) realiza un salto a una dirección relativa al PC actual (la dirección de la propia instrucción jal). Si la instrucción en ensamblador no especifica un registro de destino rd, este campo asume por defecto el valor de ra (x1). Asimismo, el salto ordinario (j) se codifica como una instrucción jal con rd = 0.

#### Codificación de valores inmediatos

RISC-V utiliza valores inmediatos de 32 bits con signo (complemento a 2). Sin embargo, debido a las restricciones de tamaño de la instrucción, solo se codifican entre 12 y 21 bits del inmediato dentro de la instrucción misma.

Como se observa en la distribución de formatos (**Imagen_7**):

Tipos I y S: Codifican inmediatos de 12 bits con signo.

Tipos J y B: Utilizan inmediatos de 21 y 13 bits con signo respectivamente, donde el bit menos significativo es siempre 0.

Tipo U: Codifica los 20 bits superiores de un inmediato de 32 bits. Los 12 bits menos significativos valen 0.

![imm_code](/imagenes/imm_encode.png "RISC-V Inmediatos")

**Imagen_7** *RISC-V Inmediatos*

El diseño de RV32I prioriza la regularidad para simplificar el hardware. A través de los diferentes formatos, se intenta mantener los bits del inmediato en las mismas posiciones de la instrucción tanto como sea posible. Esta consistencia minimiza la cantidad de cables y multiplexores necesarios para extraer y extender el signo del inmediato, aunque esto conlleve una codificación de instrucción más compleja (conocida como bit swizzling). Por ejemplo, el bit 31 de la instrucción siempre contiene el bit de signo del inmediato. 

#### Análisis de la Codificación de Operaciones (Opcodes 19, 51 y 99)

Analizando la tabla del conjunto de instrucciones RV32I, es posible determinar cómo el procesador "sabe" qué operación matemática debe realizar la ALU basándose únicamente en los bits de la instrucción.

**1. Operaciones Aritmético-Lógicas (Opcodes 19 y 51):**

Al comparar las instrucciones de tipo R *(Opcode 51 - 0110011)* con las de tipo I *(Opcode 19 - 0010011)*, se observa un patrón idéntico en el campo **funct3**:

Para sumar *(add y addi)*, el **funct3** es 000.

Para la operación AND *(and y andi)*, el **funct3** es 111.

Para la operación OR (or y ori), el funct3 es 110.

La operación matemática de la ALU se codifica principalmente en los 3 bits del campo funct3. El opcode (19 o 51) solamente le indica al procesador si el segundo número para operar proviene de un registro o es un valor inmediato, pero la operación de cálculo (suma, and, or) es la misma.

**2. Saltos Condicionales (Opcode 99):**

Las instrucciones de salto (beq, bne) tienen el opcode 99 (1100011).

Matemáticamente, para comparar si dos números son iguales (beq), el procesador debe restarlos. Si el resultado de la resta es cero, los números son iguales. Por lo tanto, aunque la instrucción sea de "salto", la ALU realiza una resta.

La condición de salto es el resultado de esa resta. El campo funct3 codifica qué condición buscar:

    000 (beq): Salta si el resultado es Cero.

    001 (bne): Salta si el resultado no es Cero. 

---

## RESULTADOS

---

## CONCLUSIONES

---

## REFERENCIAS
