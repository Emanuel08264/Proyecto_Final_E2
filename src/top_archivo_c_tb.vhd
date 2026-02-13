library ieee;
use ieee.std_logic_1164.all;
use std.env.finish;
use work.all;

entity top_archivo_c_tb is
end entity;

architecture behavioral of top_archivo_c_tb is
    constant divisor : integer := 10000000; -- Frecuencia de 10 MHz
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
    nreset <= '0';
    wait until rising_edge(clk);
    wait for periodo/4;
    nreset <= '1';
    switches <= x"0B"; 
    wait;
end process;

-- Evaluación
evaluacion: process
begin
    wait until rising_edge(clk);
    wait for 2000 * periodo;
    assert leds = "01111001" -- Salida esperada para el número 10 en el display de 7 segmentos
        report "Error: El valor de los LEDs no coincide con el de los switches."
        severity error;
    report "Test completado exitosamente.";
    finish;
end process;
end architecture;