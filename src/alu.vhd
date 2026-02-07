library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity alu is
    generic (
        constant W : positive := 32
    );
    port (
        A : in std_logic_vector (W-1 downto 0);
        B : in std_logic_vector (W-1 downto 0);
        sel_fn : in std_logic_vector (3 downto 0);
        Y : out std_logic_vector (W-1 downto 0);
        Z : out std_logic
    );
    constant WSHIFT : positive := positive(ceil(log2(real(W))));
end alu;

architecture arch of alu is
    signal shift_val: integer;
    signal SA: signed(W-1 downto 0);
    signal SB: signed(W-1 downto 0);
    signal UA: unsigned(W-1 downto 0);  
    signal UB: unsigned(W-1 downto 0);

begin
    
    SA <= signed(A);
    SB <= signed(B);
    UA <= unsigned(A);
    UB <= unsigned(B);

    shift_val <= to_integer(unsigned(B(WSHIFT-1 downto 0)));

operaciones: process(all)
    begin 
        Y <= (others => '0') ;
        case( sel_fn ) is
            --SUMA
            when "0000" =>
                Y <= std_logic_vector(SA+SB);
            --RESTA
            when "0001" =>
                Y <= std_logic_vector(SA-SB);
            --DESPLAZAMIENTO LOGICO IZQ
            when "0010" | "0011" =>
                Y <=  std_logic_vector(shift_left(UA, shift_val));
            --MENOR CON SIGNO 
            when "0100" | "0101" =>
                if SA < SB then
                    Y <= (0 => '1', others => '0');
                else
                    Y <= (others => '0');
                end if;
            --MENOR SIN SIGNO 
            when "0110" | "0111" =>
                if UA < UB then
                    Y <= (0 => '1', others => '0');
                else
                    Y <= (others => '0');
                end if;
            --XOR BIT A BIT
            when "1000" | "1001" => 
                Y <= A xor B;
            --DESPLAZAMIENTO LOGICO DER
            when "1010" =>
                Y <= std_logic_vector(shift_right(UA, shift_val));
            --DESPLAZAMIENTO ARITMETICO DER
            when "1011" =>
                Y <= std_logic_vector(shift_right(SA, shift_val));
            --OR BIT A BIT
            when "1100" | "1101" =>
                Y <= A or B;
            --AND BIT A BIT
            when "1110" | "1111" =>
                Y <= A and B;                                      
            when others =>
                Y <= (others => '0') ;
        end case ;
end process; 

Z <= '1' when unsigned(Y) = 0 else '0';

end arch ; -- arch