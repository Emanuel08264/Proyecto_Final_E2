#define GPIO_ADDR  ((volatile int *) 0x40000000)
#define MASK_DATOS  0x0F  // Switches 0,1,2,3 (0000 1111)
#define MASK_RESET  0x10  // Switch 4 (0001 0000)
#define MASK_SCORE  0x20  // Switch 5 (0010 0000)
#define MASK_NEXT   0x40  // Switch 6 (0100 0000)
#define MASK_ENTER  0x80  // Switch 7 (1000 0000)
#define MODO_SIMULACION 1

int victorias = 0;
unsigned int semilla = 0;

const int patrones[16] = {
    0x3F, // 0
    0x06, // 1
    0x5B, // 2
    0x4F, // 3
    0x66, // 4
    0x6D, // 5
    0x7D, // 6
    0x07, // 7
    0x7F, // 8
    0x6F, // 9
    0x77, // A
    0x7C, // B
    0x39, // C
    0x5E, // D
    0x79, // E
    0x71  // F
};

int random() {
    if (MODO_SIMULACION) {
        return 10; 
    } 
    else {
    // Fórmula estándar LCG (Linear Congruential Generator)
    semilla = (semilla * 1103515245 + 12345) & 0x7FFFFFFF;
    return semilla & 0x0F; 
    }
}

void delay(int n) {
    if (MODO_SIMULACION) {
        for (volatile int i = 0; i < 5; i++) {
             asm volatile("nop"); 
        }
    } 
    else {
    while (n > 0) {
        n--;
        asm volatile("nop");
        }
    }
}

void parpadear(int patron, int veces) {
    for (int i = 0; i < veces; i++) {
        *GPIO_ADDR = 0x00;     // Apagar
        delay(100000);
        *GPIO_ADDR = patron;   // Mostrar
        delay(100000);
    }
}

// --- MAIN ---
int main() {
    int lectura_sw = 0;
    int numero_objetivo = 0;
    int intento = 0;
    int estado = 0; // 0=Inicio/Espera, 1=Jugando (Mostrando numero)

    // Semilla inicial
    semilla = 1234;

    while (1) {
        lectura_sw = *GPIO_ADDR;

        // --- PRIORIDAD 1: RESET TOTAL (SW 4) ---
        if (lectura_sw & MASK_RESET) {
            victorias = 0;
            estado = 0;
            parpadear(0x40, 5); // Parpadea un guion
            // Esperar a que baje el switch para no resetear constante
            while(*GPIO_ADDR & MASK_RESET); 
        }

        // --- PRIORIDAD 2: VER PUNTAJE (SW 5) ---
        else if (lectura_sw & MASK_SCORE) {
            // Mientras SW5 esté arriba, mostramos las victorias.
            // (Si tienes display de 1 digito, solo mostramos victorias hasta 15)
            // Limitamos a 15 (F) para que entre en el display
            int mostrar = (victorias > 15) ? 15 : victorias;
            *GPIO_ADDR = patrones[mostrar]; 
            // Si SW5 baja, el while del main continuará y volverá al juego
        }

        // --- LÓGICA DEL JUEGO (Si no hay Reset ni Score) ---
        else {
            
            // MODO ESPERA / NEXT ROUND
            if (estado == 0) {
                *GPIO_ADDR = 0x40; // Mostrar guion "-"
                semilla++; // Aumentar entropía mientras espera

                // Si presiona SW6 (NEXT)
                if (lectura_sw & MASK_NEXT) {
                    numero_objetivo = random();
                    estado = 1; // Pasamos a jugar
                    // Esperar a que suelte el switch
                    while(*GPIO_ADDR & MASK_NEXT);
                }
            }
            
            // MODO JUGANDO (Adivina el binario)
            else if (estado == 1) {
                // Mostramos el número que la CPU eligió
                *GPIO_ADDR = patrones[numero_objetivo];

                // Si presiona SW7 (ENTER) para confirmar su respuesta
                if (lectura_sw & MASK_ENTER) {
                    // Leemos qué puso el usuario en SW 0-3
                    intento = lectura_sw & MASK_DATOS;

                    if (intento == numero_objetivo) {
                        // ¡GANASTE!
                        victorias++;
                        parpadear(0xFF, 3); // Festejo (Todo prendido)
                        estado = 0; // Vuelve a espera
                    } else {
                        // ¡ERROR!
                        parpadear(0x79, 3); // Muestra "E"
                        // Sigue el mismo numero y espera otro intento (no cambia estado)
                    }

                    // Esperar a que suelte el ENTER
                    while(*GPIO_ADDR & MASK_ENTER);
                }
            }
        }
    }
    return 0;
}