-- datapath del CPU RISC-V

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.all;

entity cpu is
    port(
        clk        : in std_logic;
        nreset     : in std_logic;
        bus_dsm    : in std_logic_vector (31 downto 0);
        bus_addr   : out std_logic_vector (31 downto 0);
        bus_dms    : out std_logic_vector (31 downto 0);
        bus_twidth : out std_logic_vector (2 downto 0);
        bus_tms    : out std_logic
    );
end cpu;

architecture arch of cpu is
    subtype reg32_t is std_logic_vector (31 downto 0);
    -- registros
    signal pc,pc_next : reg32_t; -- Contador de programa
    signal ir : reg32_t; -- Registro de instrucción
    -- Unidad de control
    signal jump, s1pc, wpc, wmem, wreg, sel_imm : std_logic; -- s1pc: select 1st pc
    signal data_addr, mem_source, imm_source, winst : std_logic;
    signal alu_mode : std_logic_vector (1 downto 0);
    signal imm_mode : std_logic_vector (2 downto 0);
    signal take_branch : std_logic; 
    -- ALU
    signal alu_a, alu_b, alu_y : reg32_t;
    signal alu_z : std_logic;
    signal alu_fn : std_logic_vector (3 downto 0);
    -- RF
    signal rf_din, rf_dout_a, rf_dout_b : reg32_t;
    signal rf_we : std_logic;
    signal rf_addr_w : std_logic_vector (4 downto 0);
    -- inmediato
    signal imm_val, imm_i, imm_s, imm_b, imm_u, imm_j : reg32_t;
    -- fn_alu
    signal alu_fn_i : std_logic_vector (3 downto 0);
    signal alu_fn_r : std_logic_vector (3 downto 0);
    signal alu_fn_b : std_logic_vector (3 downto 0);
    
begin

    U1 : entity control_cpu port map (
        clk => clk,
        nreset => nreset,
        take_branch => take_branch, 
        op => ir(6 downto 0),
        jump => jump,
        s1pc => s1pc,
        wpc => wpc,
        wmem => wmem,
        wreg => wreg,
        sel_imm => sel_imm,
        data_addr => data_addr,
        mem_source => mem_source,
        imm_source => imm_source,
        winst => winst,
        alu_mode => alu_mode,
        imm_mode => imm_mode
    );

    rf_addr_w <= ir(11 downto 7);
    -- x0 solo lectura
    rf_we <= wreg and (or rf_addr_w); -- es mejor hacerlo aqui o en la rf?
    rf_din <= bus_dsm when mem_source else imm_val when imm_source else alu_y;

    U2 : entity rf_32x32 port map (
        clk => clk,
        we => rf_we,
        addr_a => ir(19 downto 15),
        addr_b => ir(24 downto 20),
        addr_w => rf_addr_w,
        din    => rf_din,
        dout_a => rf_dout_a,
        dout_b => rf_dout_b
    );

    alu_a <= pc when s1pc else rf_dout_a; -- primer operando de la ALU el pc o rs1
    alu_b <= imm_val when sel_imm else rf_dout_b; -- segundo operando de la ALU, inmediato o rs2.El imm se agrega por lui, auipc

    U3 : entity alu port map (
        A => alu_a,
        B => alu_b,
        sel_fn => alu_fn,
        Y => alu_y,
        Z => alu_z
    );

    registros : process (clk)
    begin
        if rising_edge(clk) then
            if not nreset then
                pc <= (others=>'0'); -- reset pc a 0
            elsif wpc then
                pc <= pc_next; 
            end if;
            if winst then
                ir <= bus_dsm; -- cargar instrucción
            end if;
        end if;
    end process;

    pc_next <= alu_y when jump else std_logic_vector(unsigned(pc)+4); -- si hay salto, alu_y, sino pc+4

    -- Bus del sistema 
    bus_addr <= alu_y when data_addr else pc;
    bus_dms <= rf_dout_b;
    bus_twidth <= ir(14 downto 12) when data_addr else "010"; -- ancho de palabra para datos, para instrucciones fijo a 4 bytes
    bus_tms <= wmem; -- habilitación de escritura para datos
    
    -- valor inmeditao
    -- https://riscv.github.io/riscv-isa-manual/snapshot/unprivileged/#_immediate_encoding_variants
    with imm_mode select imm_val <=
                32x"4" when "000", -- valor 4 para instrucciones tipo jalr y jal
                imm_i  when "001",
                imm_s  when "010",
                imm_b  when "011",
                imm_u  when "100",
                imm_j  when others; -- "101"
    imm_i <= (31 downto 11 => ir(31)) & ir(30 downto 20); -- 12  bits con signo extendido
    imm_s <= (31 downto 11 => ir(31)) & ir(30 downto 25) & ir(11 downto 7); -- 12 bits con signo extendido
    imm_b <= (31 downto 12 => ir(31)) & ir(7) & ir(30 downto 25) & ir(11 downto 8) & "0"; -- 13 bits con signo extendido
    imm_u <= ir(31 downto 12) & (11 downto 0 => '0'); -- 20 bits + 12 ceros (lui y auipc)
    imm_j <= (31 downto 20 => ir(31)) & ir(19 downto 12) & ir(20) & ir(30 downto 21) & "0"; -- 21 bits con signo extendido

    -- Función ALU, funct3 es ir(14 downto 12) y funct7(5) es ir(30)
    -- Se compara func3 y func7 para cada instruccion a realizar, con el codigo fn_alu y 
    -- se genera la logica para obtener la operacion correcta
    with alu_mode select alu_fn <=
                alu_fn_i when "01",
                alu_fn_r when "10",
                alu_fn_b when "11",
                "0000" when others; -- "00"
    alu_fn_i <= ir(14 downto 12) & (ir(30) and ir(12));
    alu_fn_r <= ir(14 downto 12) & ir(30);
    alu_fn_b <= "0" & ir(14 downto 13) & "1";

    -- Evaluación de condición para salto condicional en función de la bandera
    -- cero de la alu, para cada caso, en función de funct3
    with ir(14 downto 12) select take_branch <=
                alu_z when "000" | "101" | "111", -- igual, mayor o igual (el resultado cero es afirmativo)
                not alu_z when others; -- distinto, menor (el resultado cero es negativo)
end arch ; -- arch