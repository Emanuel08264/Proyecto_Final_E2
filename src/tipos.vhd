
library ieee;
use ieee.std_logic_1164.all;

package tipos is
    type word_array is array (natural range <>) of std_logic_vector (31 downto 0);
end package;
