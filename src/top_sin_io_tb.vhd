library ieee;
use ieee.std_logic_1164.all;
use std.env.finish;
use work.all;

entity top_sin_io_tb is
end top_sin_io_tb;


architecture behavioral of top_sin_io_tb is
    constant divisor: integer := 10;
    constant periodo: time:= 1 sec / divisor;
    -- Señales de reloj y reset
    signal clk    : std_logic;
    signal nreset : std_logic;
begin

dut : entity top_sin_io
    port map (
        clk    => clk,
        nreset => nreset
    );

gen_clk : process
begin
    clk <= '0';
    wait for periodo/2;
    clk <= '1';
    wait for periodo/2;
end process;

estimulo: process
begin
    nreset <= '0';
    wait until rising_edge(clk);
    wait for periodo/4;
    nreset <= '1';
    wait;
end process;

evaluacion : process
begin
    wait for 200*periodo; 
    finish;
end process;

end behavioral;