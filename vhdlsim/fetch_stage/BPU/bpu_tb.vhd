LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE work.myTypes.all;
USE ieee.numeric_std.all;

ENTITY BPU_TB IS
END BPU_TB;

ARCHITECTURE bahbievfb OF BPU_TB IS
  signal pc: CODE_ADDRESS := (OTHERS => '0');
  signal clk: std_logic := '0';
  signal opcode: CODE := (OTHERS => '0');
  signal pred: std_logic;
BEGIN

  clk <= not clk after 10 ns;
  pc <= std_logic_vector(unsigned(pc)+1) after 20 ns;
  opcode <= std_logic_vector(unsigned(opcode)+1) after 20 ns;

  bpu_totest: ENTITY work.BPU PORT MAP(pc, clk, opcode, pred);
END ARCHITECTURE;
