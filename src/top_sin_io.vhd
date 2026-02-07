library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.tipos.all; 
use work.all;

entity top_sin_io is
    port (
        clk    : in std_logic;
        nreset : in std_logic
    );
end top_sin_io;

architecture structural of top_sin_io is

    -- Constante: Cantidad de esclavos conectados (Solo 1: RAM)
    constant N_SLAVES : positive := 1;

    -- 1. SEÑALES DEL BUS (LADO MAESTRO - CPU)
    signal cpu_addr    : std_logic_vector(31 downto 0);
    signal cpu_dms     : std_logic_vector(31 downto 0); 
    signal cpu_dsm     : std_logic_vector(31 downto 0);
    signal cpu_twidth  : std_logic_vector(2 downto 0);
    signal cpu_tms     : std_logic;

    -- 2. SEÑALES DEL BUS (LADO ESCLAVOS - CROSSBAR)
    -- Salidas del Crossbar hacia todos los esclavos (Bus compartido)
    signal bus_s_addr   : std_logic_vector(31 downto 0);
    signal bus_s_dms    : std_logic_vector(31 downto 0);
    signal bus_s_twidth : std_logic_vector(2 downto 0);
    signal bus_s_tms    : std_logic;

    -- Entradas al Crossbar desde los esclavos
    -- Posición 0 = RAM Controller
    signal slaves_active    : std_logic_vector(N_SLAVES-1 downto 0);
    signal slaves_data_read : word_array(N_SLAVES-1 downto 0);

    -- 3. SEÑALES DEL RAM CONTROLLER & MEMORIA FÍSICA
    
    -- Interfaz Controller -> Crossbar
    signal ram_dsm      : std_logic_vector(31 downto 0);
    signal ram_sact     : std_logic;

    -- Interfaz Controller -> Memoria Física (Señales reales)
    signal phys_ram_we   : std_logic;
    signal phys_ram_mask : std_logic_vector(3 downto 0);
    signal phys_ram_addr : std_logic_vector(8 downto 0); 
    signal phys_ram_din  : std_logic_vector(31 downto 0);
    signal phys_ram_dout : std_logic_vector(31 downto 0);

begin

    u_cpu : entity cpu
    port map (
        clk         => clk,
        nreset      => nreset,
        -- Salidas hacia el Bus
        bus_addr    => cpu_addr,
        bus_dms     => cpu_dms,
        bus_twidth  => cpu_twidth,
        bus_tms     => cpu_tms,
        -- Entrada desde el Bus
        bus_dsm     => cpu_dsm
    );

    -- INSTANCIA 2: CROSSBAR

    u_crossbar : entity crossbar
    generic map (
        num_slaves => N_SLAVES -- 1
    )
    port map (
        -- Lado Maestro (Conectado a CPU)
        bus_maddr   => cpu_addr,
        bus_mdms    => cpu_dms,
        bus_mtwidth => cpu_twidth,
        bus_mtms    => cpu_tms,
        bus_mdsm    => cpu_dsm,     -- Retorno de datos al CPU
        
        -- Lado Esclavos (Conectado a Arrays)
        bus_sact    => slaves_active,    
        bus_sdsm    => slaves_data_read, 
        
        -- Salidas hacia los Esclavos
        bus_saddr   => bus_s_addr,
        bus_sdms    => bus_s_dms,
        bus_stwidth => bus_s_twidth,
        bus_stms    => bus_s_tms
    );

    -- CONEXIÓN DE ARRAYS (Mapeo Esclavo 0 -> RAM)
    -- Conectamos las señales individuales del RAM Controller a la posición 0 de los arrays

    slaves_data_read(0) <= ram_dsm;
    slaves_active(0)    <= ram_sact;

    -- INSTANCIA 3: RAM CONTROLLER (Esclavo 0)

    u_ram_ctrl : entity ram_controller
    generic map (
        ram_addr_nbits => 9,          
        ram_base       => 32x"0" 
    )
    port map (
        clk         => clk,
        
        -- Entradas desde el Crossbar (Bus compartido)
        bus_addr    => bus_s_addr,
        bus_dms     => bus_s_dms,
        bus_twidth  => bus_s_twidth,
        bus_tms     => bus_s_tms,
        
        -- Salidas hacia el Crossbar (Individuales)
        bus_dsm     => ram_dsm,
        bus_sact    => ram_sact,
        
        -- Salidas hacia la Memoria Física
        ram_we      => phys_ram_we,
        ram_mask    => phys_ram_mask,
        ram_addr    => phys_ram_addr,
        ram_din     => phys_ram_din,
        ram_dout    => phys_ram_dout -- Entrada desde la RAM física
    );

    -- INSTANCIA 4: MEMORIA RAM FÍSICA (Para Simulación)

    u_phys_ram : entity ram_512x32
    generic map (
        init_file => "../src/ram_init.txt"
    )
    port map (
        clk      => clk,
        we       => phys_ram_we,   -- Señal de escritura generada por el controller
        addr     => phys_ram_addr, -- Dirección decodificada
        din      => phys_ram_din,  -- Dato a escribir
        dout     => phys_ram_dout,  -- Dato leído
        mask     => phys_ram_mask  -- Máscara de bytes para escrituras parciales
    );

end structural;