LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE work.myTypes.all;
USE ieee.numeric_std.all;

ENTITY BHT_ONEROW_TB IS
END BHT_ONEROW_TB;

ARCHITECTURE tb OF BHT_ONEROW_TB IS
  signal clk, en, rst, input, output: std_logic := '0';
BEGIN

  clk <= not clk after 10 ns;

  process
  begin

      rst <= '0';
      wait for 20*2 ns;

      rst <= '1';  --disable reset
      en <= '1';   --enable state register
      input <= '1'; --branches turn out to be taken
      wait for 20*4 ns;

      --right now, state should be "11" => Strong Taken.

      input <= '0'; --branches turn out to be not taken
      wait for 20*4 ns;

      --right now, state should be "00" => Strong NOT Taken.
      
      input <= '1';
      wait for 20*2 ns; --take a couple of branches,
                        --and state should now be "10" (Weak Taken)

      input <= '0';     --and now in just one clock cycle we can go back to Weak Not Taken (=output 0 again).
      wait;

  end process;


  bht_row: ENTITY work.bht_onerow PORT MAP(clk, en, rst, input, output);
END ARCHITECTURE;
