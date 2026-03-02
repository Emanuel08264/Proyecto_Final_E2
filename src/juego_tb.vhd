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
    generic map (
        init_file => "../src/ram_init_gpio_tb.txt" 
    ) 
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
    --RESET Y ARRANQUE
    nreset <= '0';
    switches <= x"00";
    wait for 100 * periodo;
    nreset <= '1';
    
    --Esperar a que el procesador arranque y llegue al main
    wait for 2000 * periodo; 

    --INICIAR JUEGO (Switch 6 - NEXT)
    switches <= x"40"; -- 0100 0000
    wait for 200 * periodo; -- Mantenemos pulsado un rato para que el C lo lea
    switches <= x"00";      -- Soltamos
    
    --ESPERA NUMERO EN DISPLAY
    wait for 1000 * periodo;

    --INGRESAR RESPUESTA Y CONFIRMAR
    switches <= x"8A"; -- 1000 1010
    wait for 200 * periodo; -- Mantenemos pulsado
    switches <= x"00";      -- Soltamos

    --ESPERA ANIMACION
    wait for 2000 * periodo; 

    --INICIAR JUEGO (Switch 6 - NEXT)
    switches <= x"40"; -- 0100 0000
    wait for 200 * periodo; -- Mantenemos pulsado un rato para que el C lo lea
    switches <= x"00";      -- Soltamos
    
    --ESPERA NUMERO EN DISPLAY
    wait for 1000 * periodo;

    --INGRESAR RESPUESTA Y CONFIRMAR
    switches <= x"8B"; -- 1000 1011
    wait for 200 * periodo; -- Mantenemos pulsado
    switches <= x"00";      -- Soltamos

    --ESPERA ANIMACION
    wait for 2000 * periodo;

    --SCORE
    switches <= x"20"; -- 0010 0000
    wait for 200 * periodo;
    switches <= x"00";
    
    --ESPERA VER SCORE
    wait for 2000 * periodo;

    --INGRESAR RESPUESTA Y CONFIRMAR
    switches <= x"8A"; -- 1000 1010
    wait for 200 * periodo; -- Mantenemos pulsado
    switches <= x"00";      -- Soltamos

    --ESPERA ANIMACION
    wait for 2000 * periodo;

    -- SCORE
    switches <= x"20"; -- 0010 0000
    wait for 200 * periodo;
    switches <= x"00";

    --ESPERA VER SCORE
    wait for 2000 * periodo;

    finish;
end process;

-- Evaluación (Visual)
evaluacion: process
begin
    wait until rising_edge(clk);
    wait for 23000 * periodo; 
    finish; -- Detener aqui si el otro process no lo hizo
end process;
end architecture;