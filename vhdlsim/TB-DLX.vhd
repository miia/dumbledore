LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;

ENTITY TB_DLX IS
  END TB_DLX;

ARCHITECTURE tb OF TB_DLX IS
  SIGNAL CLK: in std_logic := '0';
  SIGNAL RESET: in std_logic := '0';
  SIGNAL POUT: out std_logic;
BEGIN
  toTest: entity work.DLX PORT MAP( CLK, RESET, POUT);

  CLK <= not CLK after 10 ns;

  process begin
    RESET <= '0';
    wait for 30 ns;
    RESET <= '1';
    wait;
  end process;

END ARCHITECTURE;
