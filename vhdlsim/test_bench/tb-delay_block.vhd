LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE IEEE.numeric_std.ALL;
ENTITY TB_DELAY_BLOCK IS
END ENTITY;

ARCHITECTURE TEST OF TB_DELAY_BLOCK is
signal RESET: std_logic;
signal CLK: std_logic := '0';
signal D, Q: std_logic_vector(3 downto 0) := (OTHERS => '0');
BEGIN
  CLK <= not CLK after 10 ns;

  RESET <= '0', '1' after 35 ns;
  process begin
    D <= std_logic_vector(unsigned(D)+1);
    wait for 20 ns;
  end process;

  toTest: ENTITY work.DELAY_BLOCK
  GENERIC MAP(WIDTH => 4, NREGS => 3) PORT MAP(D => D, CLK => CLK, RESET => RESET, Q => Q);
END ARCHITECTURE;
