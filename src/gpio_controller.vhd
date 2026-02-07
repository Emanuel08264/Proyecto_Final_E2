library ieee;
use ieee.std_logic_1164.all;

entity gpio_controller is
    generic (
        constant GPIO_ADDR : std_logic_vector(31 downto 0) := x"40000000" -- Dirección base para el controlador GPIO
    );
    port (
        clk    : in std_logic;
        nreset : in std_logic;
        -- Interfaz con el Bus (Crossbar)
        bus_addr   : in std_logic_vector(31 downto 0);
        bus_dms    : in std_logic_vector(31 downto 0);
        bus_tms    : in std_logic;
        bus_dsm    : out std_logic_vector(31 downto 0);
        bus_sact   : out std_logic; 
        -- Interfaz con los GPIOs físicos
        gpio_in  : in std_logic_vector(7 downto 0); -- 8 pines de entrada
        gpio_out : out std_logic_vector(7 downto 0) -- 8 pines de salida
    );
end entity;

architecture arch of gpio_controller is
begin

    bus_sact <= '1' when bus_addr = GPIO_ADDR else '0';  
    
    -- Salida de datos hacia el bus: Si nos seleccionan y quieren leer, enviamos el estado de los GPIOs de entrada
    process(all)
    begin
        if bus_tms = '0' and bus_sact = '1' and nreset = '1' then
            bus_dsm <= (31 downto 8 => '0') & gpio_in;
        else
            bus_dsm <= (others => '0');
        end if;
    end process;

    process(clk)
    begin
        if rising_edge(clk) then
            if nreset = '0' then
                gpio_out <= (others => '0'); -- Reset
            else
                -- Si nos seleccionan Y quieren escribir (WE='1')
                if bus_tms = '1' and bus_sact = '1' then
                    gpio_out <= bus_dms(7 downto 0);
                end if;
            end if;
        end if;
    end process;

end arch;