library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;


entity ram_controller is 
    generic (
        constant ram_addr_nbits : positive range 1 to 30 := 9; 
        constant ram_base : std_logic_vector (31 downto 0) := 32x"0"
    );
    port (
        clk        : in  std_logic;
        bus_addr   : in  std_logic_vector (31 downto 0);
        bus_dms    : in  std_logic_vector (31 downto 0);
        bus_twidth : in  std_logic_vector (2 downto 0);
        bus_tms    : in  std_logic;
        bus_dsm    : out std_logic_vector (31 downto 0);
        bus_sact   : out std_logic;
        ram_we     : out std_logic;
        ram_mask   : out std_logic_vector (3 downto 0);
        ram_addr   : out std_logic_vector (ram_addr_nbits - 1 downto 0);
        ram_din    : out std_logic_vector (31 downto 0);
        ram_dout   : in  std_logic_vector (31 downto 0)
    );
end ram_controller;

architecture arch of ram_controller is
    signal sact : std_logic;
    signal reg_twidth : std_logic_vector (2 downto 0);
    signal reg_offset : std_logic_vector (1 downto 0);
    signal base_mask : std_logic_vector (3 downto 0); -- señal intermedia para la máscara base
    signal ram_dout_aligned : std_logic_vector (31 downto 0);
begin
    registros : process (clk)
    begin
        if rising_edge(clk) then
            bus_sact <= sact;
            reg_twidth <= bus_twidth;
            reg_offset <= bus_addr(1 downto 0); -- guarda el offset de la dirección
        end if;
    end process;
    sact <= ram_base(31 downto ram_addr_nbits + 2) ?= bus_addr(31 downto ram_addr_nbits + 2); 
    ram_we <= sact and bus_tms; -- Habilita escritura solo si la dirección está dentro del rango y tms está activo
    ram_addr <= bus_addr(ram_addr_nbits + 1 downto 2); -- Divide la direccion por 4. Despalaza 2 bits a la derecha
    ram_din <= bus_dms sll (8 * to_integer(unsigned(bus_addr(1 downto 0)))); -- Alinea los datos de entrada según el offset
    with bus_twidth(1 downto 0) select base_mask <= -- genera la máscara base según el ancho de datos
            "0001" when "00",
            "0011" when "01",
            "1111" when others; -- "11"
    ram_mask <= base_mask sll to_integer(unsigned(bus_addr(1 downto 0))); -- ajusta la máscara según el offset
    ram_dout_aligned <= ram_dout srl (8 * to_integer(unsigned(reg_offset))); -- Alinea los datos de salida según el offset

    -- Ajusta los datos de salida según el ancho de datos, extendiendo el signo si es necesario
    with reg_twidth select bus_dsm <=
            (31 downto 7 => ram_dout_aligned(7)) & ram_dout_aligned(6 downto 0) when "000", 
            (31 downto 8 => '0') & ram_dout_aligned(7 downto 0) when "100",
            (31 downto 15 => ram_dout_aligned(15)) & ram_dout_aligned(14 downto 0) when "001",
            (31 downto 16 => '0') & ram_dout_aligned(15 downto 0) when "101",
            ram_dout_aligned when others; -- "010"
end arch ; -- arch