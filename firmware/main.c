#define GPIO_ADDR  ((volatile int *) 0x40000000)

void delay(int n) {
    while (n > 0) {
        n--;
        asm volatile("nop");
    }
}

int main() {
    int valor_leido = 0;
    int valor_a_mostrar = 0;

    while (1) {
        // Lee los switches
        valor_leido = *GPIO_ADDR;

        // Suma 3 al valor leído
        valor_a_mostrar = valor_leido + 3;

        // Asegura que solo se muestren los 4 bits menos significativos (0-15). (Solo por claridad)
        valor_a_mostrar = valor_a_mostrar & 0x0F; 

        // Escribe en el Display
        *GPIO_ADDR = valor_a_mostrar;
        
        // Esperamos un poco para que no parpadee si los switches rebotan
        delay(5); 
    }

    return 0;
}