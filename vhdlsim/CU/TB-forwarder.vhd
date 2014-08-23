LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE work.myTypes.ALL;

ENTITY TB_FORWARDER IS
END TB_FORWARDER;

ARCHITECTURE test OF TB_FORWARDER IS
  SIGNAL CLK: std_logic := '0';
  SIGNAL RESET: std_logic := '0';
  SIGNAL IR: INSTRUCTION;
  SIGNAL SELECT_RIGHTA, SELECT_RIGHTB: std_logic_vector(1 downto 0);
BEGIN
  CLK <= not CLK after 10 ns;
  RESET <= '1' after 15 ns;
  toTest: entity work.FORWARDER
  PORT MAP(CLK => CLK, RESET => RESET, IR => IR, SELECT_RIGHTA => SELECT_RIGHTA, SELECT_RIGHTB => SELECT_RIGHTB);
process begin
  IR <= x"00002020";
  wait for 30 ns; -- Instruction  will arrive always on clock edges from the fetch unit, so we align to this
  IR <= x"2001000A";
  wait for 20 ns;
  IR <= x"2002001E";
  wait for 20 ns;
  IR <= x"0081F020";
  wait for 20 ns;
  IR <= x"2BDE0001";
  wait for 20 ns;
  IR <= x"0BFFFFE8";
  wait for 20 ns;
end process;
END ARCHITECTURE;
