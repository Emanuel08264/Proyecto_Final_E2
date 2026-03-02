library ieee;
use ieee.std_logic_1164.all;
use std.env.finish;
use work.all;

entity top_suma_c_tb is
end entity;

architecture behavioral of top_suma_c_tb is
    constant divisor : integer := 10000000; 
    constant periodo : time := 1 sec / divisor;
    signal clk    : std_logic := '0';
    signal nreset : std_logic := '0';
    signal switches : std_logic_vector(7 downto 0) := (others => '0');
    signal leds     : std_logic_vector(7 downto 0);
begin

u_top: entity top
    generic map (
        init_file => "../src/suma_c.txt" 
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
    nreset <= '0';
    wait until rising_edge(clk);
    wait for periodo/4;
    nreset <= '1';
    switches <= x"0B"; -- Establece el valor 11 (0x0B) en los switches
    wait;
end process;

-- Evaluación
evaluacion: process
begin
    wait until rising_edge(clk);
    wait for 5000 * periodo;
    report "Valor ingresado en los switches: " & to_string(switches);
    report "Valor mostrado en los LEDs: " & to_string(leds);
    assert leds = "01111001" -- Espera el numero 14 en el display de 7 segmentos
        report "Error: El valor de los LEDs no coincide con el esperado: 01111001"
        severity error;
    if leds = "01111001" then
        report "Test completado exitosamente.";
    end if;
    finish;
end process;
end architecture;