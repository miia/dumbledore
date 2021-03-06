LIBRARY IEEE;
use IEEE.std_logic_1164.ALL;

ENTITY TB_pc_acc IS
END TB_pc_acc;

ARCHITECTURE tb OF TB_pc_acc IS
constant WIDTH : integer := 32;
signal IMMEDIATE:		std_logic_vector(WIDTH-1 downto 0);
signal NEW_VALUE:		std_logic_vector(WIDTH-1 downto 0);
signal CLK:		std_logic := '0';
signal RESET:		std_logic;
signal ACC_ENABLE:  std_logic; -- Active low
signal ACC_JMP:		std_logic;
signal OVERWRITE:		std_logic;
signal Y: std_logic_vector(WIDTH-1 downto 0);
BEGIN
  to_test: ENTITY work.PC_ACC
  GENERIC MAP(WIDTH => 32) PORT MAP(IMMEDIATE => IMMEDIATE, NEW_VALUE => NEW_VALUE, CLK => CLK, RESET => RESET, ACC_ENABLE => ACC_ENABLE, ACC_JMP => ACC_JMP, OVERWRITE => OVERWRITE, Y => Y);

  CLK <= not CLK after 5 ns;

process begin
  IMMEDIATE <= (OTHERS => '0');
  NEW_VALUE <= (OTHERS => '0');
  OVERWRITE <= '0';
  RESET <= '0';
  ACC_ENABLE <= '0';
  ACC_JMP <= '0';
  wait for 15 ns;
  RESET <= '1';
  wait for 15 ns;
  NEW_VALUE <= (5 => '1', OTHERS => '0');
  OVERWRITE <= '1';
  wait for 5 ns;
  wait for 15 ns;
  OVERWRITE <= '0';
  IMMEDIATE <= (3 => '1', OTHERS => '0');
  ACC_JMP <= '1';
  wait;
end process;
end architecture;
