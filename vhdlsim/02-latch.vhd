LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
--Transparent latch. Transparent mode for CLK='0', latched for CLK='1'.
ENTITY LATCH_GENERIC IS
  GENERIC(WIDTH: integer := 8);
  PORT(D : in std_logic_vector(WIDTH-1 downto 0); CLK : in std_logic; RESET: in std_logic; Q : out std_logic_vector(WIDTH-1 downto 0));
END LATCH_GENERIC;

ARCHITECTURE behavioural OF LATCH_GENERIC IS
BEGIN
  keep_data: process(D, RESET, CLK) begin
    if(RESET = '0') then
      Q <= (OTHERS => '0');
    elsif(CLK = '0') then
      Q <= D;
    end if;
  end process;
END ARCHITECTURE;
