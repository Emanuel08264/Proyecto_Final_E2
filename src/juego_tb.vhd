library ieee;
use ieee.std_logic_1164.all;
use std.env.finish;
use work.all;

entity juego_tb is
end entity;

architecture behavioral of juego_tb is
    constant divisor : integer := 10000000; 
    constant periodo : time := 1 sec / divisor;
    signal clk    : std_logic := '0';
    signal nreset : std_logic := '0';
    signal switches : std_logic_vector(7 downto 0) := (others => '0');
    signal leds     : std_logic_vector(7 downto 0);
begin

u_top: entity top 
    port map (
        clk      => clk,
        nreset_in   => nreset,
        switches => switches,
        leds     => leds
    );

-- Reloj
clk_process : process 
begin 
    clk <= '0';
    wait for periodo / 2;
    clk <= '1';
    wait for periodo / 2;
end process;

-- Estímulo
estimulo: process
begin
    report "--- INICIO DE SIMULACION (Target = 10 / 0xA) ---";
    
    -- 1. RESET Y ARRANQUE
    nreset <= '0';
    switches <= x"00";
    wait for 100 * periodo;
    nreset <= '1';
    
    -- IMPORTANTE: Esperar a que el procesador arranque y llegue al main
    wait for 2000 * periodo; 

    -- 2. INICIAR JUEGO (Switch 6 - NEXT)
    report "ACCION: Presionando NEXT (SW6)...";
    switches <= x"40"; -- 0100 0000
    wait for 200 * periodo; -- Mantenemos pulsado un rato para que el C lo lea
    switches <= x"00";      -- Soltamos
    
    -- Esperar a que la CPU calcule y muestre el número en el display
    wait for 1000 * periodo;

    -- 3. INGRESAR RESPUESTA Y CONFIRMAR
    -- El target es 10 (decimal) -> A (Hex) -> 1010 (Binario)
    -- Switch ENTER es el bit 7 (0x80)
    -- Queremos enviar: ENTER + DATOS = 0x80 OR 0x0A = 0x8A
    
    report "ACCION: Ingresando 10 (0xA) y confirmando (SW7)...";
    switches <= x"8A"; -- 1000 1010
    wait for 200 * periodo; -- Mantenemos pulsado
    switches <= x"00";      -- Soltamos

    -- 4. VERIFICACION VISUAL (Opcional, el assert lo hará abajo)
    wait for 8000 * periodo;
    report "Simulacion de juego terminada. Revisa si hubo festejo (0xFF).";
    
    finish;
end process;

-- Evaluación (Assertions para comprobar victoria)
evaluacion: process
begin
    wait until rising_edge(clk);
    -- Esperamos hasta el momento donde debería ocurrir la victoria
    -- (Suma de todos los tiempos de arriba aprox: 2000+200+1000+200 = ~3500)
    wait for 8000 * periodo; 
    
    -- Si ganamos, el código C hace parpadear todo (0xFF)
    -- Si perdimos, muestra una 'E' (0x79)
    if leds = x"FF" then
        report "EXITO: ¡Victoria detectada! (LEDs = FF)";
    elsif leds = x"79" then
        report "FALLO: Se detectó error (LEDs = E). Revisar lógica.";
    else
        report "ADVERTENCIA: Estado final desconocido: " & to_string(leds);
    end if;
    
    finish; -- Detener aqui si el otro process no lo hizo
end process;
end architecture;