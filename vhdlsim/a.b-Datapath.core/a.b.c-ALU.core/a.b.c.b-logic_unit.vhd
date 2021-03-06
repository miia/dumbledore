library IEEE;
use IEEE.std_logic_1164.all;

entity LOGIC_UNIT is
  generic (N : integer := 32);
  port 	 ( FUNC: IN std_logic_vector(1 downto 0);
           A, B: IN std_logic_vector(N-1 downto 0);
           Y: OUT std_logic_vector(N-1 downto 0));
end LOGIC_UNIT;

architecture BEHAVIOR of LOGIC_UNIT is

begin

P_ALU: process (FUNC, A, B)
  begin
    case FUNC is
      when "01" 	=> Y <= A and B; -- bitwise operations
      when "00" 	=> Y <= A or B;--
      when "10" 	=> Y <= A  xor B;
      when "11" => Y <= not A; 
      when others => NULL;
    end case; 
  end process P_ALU;

end BEHAVIOR;
