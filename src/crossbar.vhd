library ieee;
use ieee.std_logic_1164.all;
use work.tipos.all;

entity crossbar is 
    generic (
        constant num_slaves : positive := 1
    );
    port (
        bus_maddr : in std_logic_vector(31 downto 0); -- direccion que envia el maestro
        bus_mdms : in std_logic_vector (31 downto 0); -- datos que envia el maestro
        bus_mtwidth : in std_logic_vector (2 downto 0); -- ancho de datos que envia el maestro
        bus_mtms : in std_logic; -- señal de control que envia el maestro, que indica si hay datos válidos
        bus_sact : in std_logic_vector (num_slaves - 1 downto 0); -- indica cuantos esclavos estan activos
        bus_sdsm : in word_array(num_slaves - 1 downto 0); -- matriz que contiene los datos de cada esclavo
        bus_mdsm : out std_logic_vector (31 downto 0); -- vector con los datos que le llegan de un esclavo
        bus_saddr : out std_logic_vector (31 downto 0); -- direccion que se envia al esclavo. 
        bus_sdms : out std_logic_vector (31 downto 0); -- datos que se envian al esclavo
        bus_stwidth : out std_logic_vector (2 downto 0); -- ancho de datos que se envia al esclavo
        bus_stms : out std_logic -- señal de control que se envia al esclavo, que indica si hay datos válidos
    );
end entity;

architecture arch of crossbar is
begin
    -- Señales controladas por el maestro
    bus_saddr <= bus_maddr;
    bus_sdms  <= bus_mdms;
    bus_stwidth <= bus_mtwidth;
    bus_stms <= bus_mtms;

    -- Mux
    dsm_mux : process (all)
        variable mux_out : std_logic_vector(31 downto 0);
    begin
        mux_out := 32x"0";
        for i in num_slaves - 1 downto 0 loop
            if bus_sact(i) then
                mux_out := mux_out or bus_sdsm(i); -- Si el esclavo i está activo, toma sus datos
            end if;
        end loop;
        bus_mdsm <= mux_out;
    end process;

end arch ; -- arch
