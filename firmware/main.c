#define GPIO_ADDR  ((volatile int *) 0x40000000)

void delay(int n) {
    while (n > 0) {
        n--;
        asm volatile("nop");
    }
}
const int patrones_7seg[16] = {
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

int main() {
    int valor_leido = 0;
    int valor_a_mostrar = 0;

    while (1) {
        // Lee los switches
        valor_leido = *GPIO_ADDR;

        // Suma 3 al valor leído
        valor_a_mostrar = valor_leido + 3;

        // Asegura que solo se muestren los 4 bits menos significativos 
        valor_a_mostrar = valor_a_mostrar & 0x0F; 

        // Escribe en el Display
        *GPIO_ADDR = patrones_7seg[valor_a_mostrar];
        
        // Esperamos un poco para que no parpadee si los switches rebotan
        delay(5); 
    }

    return 0;
}