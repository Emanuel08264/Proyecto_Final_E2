library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity reset_al_inicializar_fpga is
    port (
        clk : in std_logic;
        nreset_in : in std_logic; -- nreset activado por un switch externo
        nreset_out : out std_logic -- nreset para el resto de la FPGA
    );
end reset_al_inicializar_fpga;

architecture arch of reset_al_inicializar_fpga is
    -- SB_RAM40_4K es 256x16 bit
    -- Ram fisica de la fpga, se inicializa con 0x0000, se escribe 0xFFFF en la dirección 0x00
    -- y se lee continuamente la dirección 0x00 para generar el reset
    type ram_t is array (255 downto 0) of std_logic_vector (15 downto 0); 
    
    signal datos : ram_t := (others => 16x"0");

    signal addr : unsigned (7 downto 0);
    signal din : std_logic_vector (15 downto 0);
    signal dout : std_logic_vector (15 downto 0);
    signal we : std_logic;
begin

    U_RAM : process (clk)
        variable i : integer;
    begin
        if rising_edge(clk) then
            i := to_integer(addr);
            dout <= datos(i);
            if we then -- en el primer ciclo we es 1, se escribe 0xFFFF en la dirección 0x00, luego we es 0 y se lee continuamente la dirección 0x00
                datos(i) <= din;
            end if;
        end if; 
    end process;

    addr <= 8x"0";
    din <= 16x"FFFF";
    we <= not dout(0);
    nreset_out <= dout(0) and nreset_in;
end arch ; -- arch