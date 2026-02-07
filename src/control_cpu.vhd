-- FMS que activa las señales de control del CPU 
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity control_cpu is
    port (
        clk        : in  std_logic;
        nreset     : in  std_logic;
        take_branch: in  std_logic;
        op         : in  std_logic_vector (6 downto 0);
        jump       : out std_logic;
        s1pc       : out std_logic;
        wpc        : out std_logic;
        wmem       : out std_logic;
        wreg       : out std_logic;
        sel_imm    : out std_logic;
        data_addr  : out std_logic;
        mem_source : out std_logic;
        imm_source : out std_logic;
        winst      : out std_logic;
        alu_mode   : out std_logic_vector (1 downto 0);
        imm_mode   : out std_logic_vector (2 downto 0)
    );
end control_cpu;

architecture arch of control_cpu is
    type estado_t is (
        INICIO, 
        LEE_MEM_PC, 
        CARGA_IR, 
        DECODIFICA, 
        CALC_ADDR_LS,       -- Estado común para calcular dirección Load/Store
        CARGA_RD_DE_MEM,    -- Fase final Load
        ESCRIBE_RS2_A_MEM,  -- Fase final Store 
        EJECUTA_R_TYPE,     
        EJECUTA_I_TYPE,     
        SALTO, -- Estado común para branch tomado, JAL y JALR
        EJECUTA_BRANCH,
        EJECUTA_JAL_JALR,
        EJECUTA_LUI,
        EJECUTA_AUIPC        
    );
    signal estado_sig, estado : estado_t;

    subtype imm_mode_t is std_logic_vector (2 downto 0);
    constant IMM_CONST_4 : imm_mode_t := "000";
    constant IMM_I : imm_mode_t := "001";
    constant IMM_S : imm_mode_t := "010";
    constant IMM_B : imm_mode_t := "011";
    constant IMM_U : imm_mode_t := "100";
    constant IMM_J : imm_mode_t := "101";

    subtype opcode_t is std_logic_vector (6 downto 0);
    constant OPC_LOAD : opcode_t := "0000011";
    constant OPC_STORE : opcode_t := "0100011";
    constant OPC_ALUI : opcode_t := "0010011";
    constant OPC_ALUR : opcode_t := "0110011";
    constant OPC_BRANCH : opcode_t := "1100011";
    constant OPC_JAL : opcode_t := "1101111";
    constant OPC_JALR : opcode_t := "1100111";
    constant OPC_LUI : opcode_t := "0110111";
    constant OPC_AUIPC : opcode_t := "0010111";

    subtype alu_mode_t is std_logic_vector (1 downto 0);
    constant ALU_ADD : alu_mode_t := "00";
    constant ALU_IMM : alu_mode_t := "01";
    constant ALU_R : alu_mode_t := "10";
    constant ALU_BRANCH : alu_mode_t := "11";

begin

    registros : process (clk)
    begin
        if rising_edge(clk) then
            if not nreset then
                estado <= INICIO;
            else
                estado <= estado_sig;
            end if;
        end if;
    end process;

    logica_estado_sig : process (all)
    begin
        estado_sig <= INICIO;
        case( estado ) is
        
            when INICIO =>
                estado_sig <= LEE_MEM_PC;
            when LEE_MEM_PC =>
                estado_sig <= CARGA_IR;
            when CARGA_IR =>
                estado_sig <= DECODIFICA;
            when DECODIFICA =>
                case( op ) is
                    when OPC_LOAD | OPC_STORE=>
                        estado_sig <= CALC_ADDR_LS;
                    when OPC_ALUR =>
                        estado_sig <= EJECUTA_R_TYPE;
                    when OPC_ALUI =>
                        estado_sig <= EJECUTA_I_TYPE;
                    when OPC_BRANCH =>
                        estado_sig <= EJECUTA_BRANCH;
                    when OPC_JAL | OPC_JALR =>
                        estado_sig <= EJECUTA_JAL_JALR;
                    when OPC_LUI =>
                        estado_sig <= EJECUTA_LUI;
                    when OPC_AUIPC =>
                        estado_sig <= EJECUTA_AUIPC;
                    when others =>
                end case; 

            when CALC_ADDR_LS =>
                    if op = OPC_LOAD then 
                        estado_sig <= CARGA_RD_DE_MEM;
                    else
                        estado_sig <= ESCRIBE_RS2_A_MEM;
                    end if;

            when CARGA_RD_DE_MEM | ESCRIBE_RS2_A_MEM | EJECUTA_R_TYPE |  
                 EJECUTA_I_TYPE |EJECUTA_LUI | EJECUTA_AUIPC | SALTO =>
                    estado_sig <= LEE_MEM_PC;

            when EJECUTA_BRANCH =>
                if take_branch then
                    estado_sig <= SALTO;
                else
                    estado_sig <= LEE_MEM_PC;
                end if;

            when EJECUTA_JAL_JALR => 
                estado_sig <= SALTO;

            when others =>
        end case ;
    end process;

    logica_salida : process (all)
    begin
        wpc <= '0';
        wmem <= '0';
        winst <= '0';
        wreg <= '0';
        jump <= '0';
        s1pc <= '0';
        alu_mode <= ALU_ADD;
        imm_mode <= IMM_CONST_4;
        sel_imm <= '0';
        data_addr <= '0';
        mem_source <= '0';
        imm_source <= '0';
        case (estado) is
            when INICIO =>
                -- por defecto
            when LEE_MEM_PC =>
                -- por defecto
            when CARGA_IR =>
                winst <= '1';
            when DECODIFICA =>
                -- por defecto
            when CALC_ADDR_LS => -- suma pc + 4, y rs1 + inmediato para la dirección de memoria
                sel_imm <= '1';
                if op = OPC_LOAD then
                    imm_mode <= IMM_I;
                else
                    imm_mode <= IMM_S;
                end if;
                data_addr <= '1'; 
            when CARGA_RD_DE_MEM =>
                sel_imm <= '1';
                imm_mode <= IMM_I;
                data_addr <= '1';  
                mem_source <= '1'; -- elige la memoria como fuente de datos para escribir en rd
                wreg <= '1'; -- habilita escritura en rd
                wpc <= '1'; -- actualiza pc
            when ESCRIBE_RS2_A_MEM =>
                sel_imm <= '1';
                imm_mode <= IMM_S;
                data_addr <= '1';
                wmem <= '1'; -- habilita escritura en memoria
                wpc <= '1'; -- actualiza pc
            when EJECUTA_R_TYPE =>
                alu_mode <= ALU_R;
                wreg <= '1'; -- habilita escritura en rd
                wpc <= '1'; -- actualiza pc
            when EJECUTA_I_TYPE =>
                alu_mode <= ALU_IMM;
                sel_imm <= '1';
                imm_mode <= IMM_I;
                wreg <= '1'; -- habilita escritura en rd
                wpc <= '1'; -- actualiza pc
            when EJECUTA_BRANCH => -- obtengo take_branch de cpu.vhd, y en el siguiente ciclo salto o no
                alu_mode <= ALU_BRANCH;
                if take_branch = '0' then
                    wpc <= '1';
                end if;
            when SALTO => -- salto reunido para JAL, JALR y branch tomado
                sel_imm <= '1';
                jump <= '1';
                wpc <= '1';
                if op = OPC_JAL then
                    s1pc <= '1';
                    imm_mode <= IMM_J;
                elsif op = OPC_BRANCH then
                    s1pc <= '1';
                    imm_mode <= IMM_B;
                else -- JALR
                    imm_mode <= IMM_I;
                end if;
            when EJECUTA_JAL_JALR => -- guardo en rd la pc+4 y en el  siguiente ciclo salto
                sel_imm <= '1';
                wreg <= '1';
                s1pc <= '1';
                imm_mode <= IMM_CONST_4;
            when EJECUTA_LUI =>
                imm_mode <= IMM_U;
                imm_source <= '1';
                wreg <= '1';
                wpc <= '1';
            when EJECUTA_AUIPC =>
                s1pc <= '1';
                sel_imm <= '1';
                imm_mode <= IMM_U;
                wreg <= '1';
                wpc <= '1';
            when others =>
        end case;
    end process;
end arch ; -- arch