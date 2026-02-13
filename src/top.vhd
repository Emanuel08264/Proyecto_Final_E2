library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.tipos.all; 
use work.all;

entity top is
    port (
        clk    : in std_logic;
        nreset_in : in std_logic;

        switches : in std_logic_vector(7 downto 0); -- 8 switches de entrada
        leds     : out std_logic_vector(7 downto 0) -- 8 LEDs de salida
    );
end top;

architecture structural of top is

    -- Constante: Cantidad de esclavos conectados (Solo 1: RAM)
    constant N_SLAVES : positive := 2;

    -- 0. SEÑALES DE RESET
    signal system_nreset : std_logic;

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
    -- Posición 1 = GPIO Controller
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

    -- 4. SEÑALES DEL GPIO CONTROLLER & DISPLAY 7 SEGMENTOS
    signal gpio_dsm      : std_logic_vector(31 downto 0);
    signal gpio_sact     : std_logic;
    signal numero_segmentos : std_logic_vector(3 downto 0);

begin

    -- INSTANCIA 0: MÓDULO DE RESET
    u_reset : entity reset_al_inicializar_fpga
    port map (
        clk => clk,
        nreset_in => nreset_in,
        nreset_out => system_nreset
    );

    -- INSTANCIA 1: CPU

    u_cpu : entity cpu
    port map (
        clk         => clk,
        nreset      => system_nreset,
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

    -- INSTANCIA 4: MEMORIA RAM 

    u_phys_ram : entity ram_512x32
    generic map (
        init_file => "../src/ram_init_gpio.txt"
    )
    port map (
        clk      => clk,
        we       => phys_ram_we,   -- Señal de escritura generada por el controller
        addr     => phys_ram_addr, -- Dirección decodificada
        din      => phys_ram_din,  -- Dato a escribir
        dout     => phys_ram_dout,  -- Dato leído
        mask     => phys_ram_mask  -- Máscara de bytes para escrituras parciales
    );
    
    -- CONEXIÓN DE ARRAYS (Mapeo Esclavo 1 -> GPIO)
    -- Conectamos las señales individuales del GPIO Controller a la posición 1 de los arrays
    slaves_data_read(1) <= gpio_dsm;
    slaves_active(1)    <= gpio_sact;
    
    -- Instancia 5: GPIO Controller (Esclavo 1)
    u_gpio_ctrl : entity gpio_controller
    generic map (
        GPIO_ADDR => x"40000000" -- Dirección base para el controlador GPIO
    )
    port map (
        clk         => clk,
        nreset      => system_nreset,
        -- Entradas desde el Crossbar (Bus compartido)
        bus_addr    => bus_s_addr,
        bus_dms     => bus_s_dms,
        bus_tms     => bus_s_tms,
        -- Salidas hacia el Crossbar (Individuales)
        bus_dsm     => gpio_dsm, -- Retorno de datos al Crossbar
        bus_sact    => gpio_sact,     -- Indica si el GPIO está activo

        gpio_in     => switches, -- Conectamos los switches a las entradas del GPIO
        gpio_out    => numero_segmentos      -- Conectamos las salidas del GPIO a los LEDs
    );

    -- Instancia 6: Display 7 segmentos
    u_siete_segmentos : entity siete_seg
    port map (
        D => numero_segmentos,
        Y => leds(6 downto 0)
    );
    leds(7) <= '0';
end structural;