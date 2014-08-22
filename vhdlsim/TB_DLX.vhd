LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;

ENTITY TB_DLX IS
END TB_DLX;
ARCHITECTURE TEST OF TB_DLX IS
  signal CLK: std_logic := '0';
  signal RESET: std_logic;
  signal POUT: std_logic_vector(31 downto 0); -- Connected to R30
BEGIN
  -- Fetch unit will automatically fetch instruction and execute them, all we have to do is let it go :)
  toTest: ENTITY work.DLX PORT MAP(CLK, RESET, POUT);
  RESET <= '0', '1' after 15 ns;
  CLK <=  not CLK after 10 ns;
END ARCHITECTURE;
