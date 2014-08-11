LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE work.myTypes.ALL;

ENTITY TB_DLX IS
  END TB_DLX;

ARCHITECTURE tb OF TB_DLX IS
  SIGNAL CLK: std_logic := '0';
  SIGNAL RESET: std_logic := '0';
  SIGNAL POUT: REGISTER_CONTENT;
BEGIN
  toTest: entity work.DLX PORT MAP( CLK, RESET, POUT);

  CLK <= not CLK after 10 ns;

  RESET <= '0', '1' after 30 ns;

END ARCHITECTURE;
