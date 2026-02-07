library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all;

entity rf_32x32 is
    port (
        clk     : in  std_logic;

        we      : in  std_logic;
        addr_w    : in  std_logic_vector(4 downto 0);
        din     : in  std_logic_vector(31 downto 0);

        addr_a    : in  std_logic_vector(4 downto 0);
        dout_a    : out std_logic_vector(31 downto 0);

        addr_b    : in  std_logic_vector(4 downto 0);
        dout_b    : out std_logic_vector(31 downto 0)
    );
end entity rf_32x32;

architecture behavioral of rf_32x32 is
    type ram_type is array (31 downto 0) of std_logic_vector(31 downto 0);
    signal register_f : ram_type := (others => (others => '0'));

begin
    process(clk)
    begin
        if rising_edge(clk) then
            if we = '1' and addr_w /= "00000" then -- El registro 0 es siempre 0
                register_f(to_integer(unsigned(addr_w))) <= din;
            end if;
        end if;
        dout_a <= register_f(to_integer(unsigned(addr_a)));
        dout_b <= register_f(to_integer(unsigned(addr_b))); 
    end process;
    
end architecture behavioral;