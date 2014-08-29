LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE work.myTypes.all;
USE ieee.numeric_std.all;

PACKAGE DEMUX_GENERIC_OUTPUT IS
  TYPE demux_generic_output IS ARRAY (NATURAL RANGE <>, NATURAL RANGE <>) OF STD_LOGIC;
END PACKAGE demux_generic_output;

use WORK.DEMUX_GENERIC_OUTPUT.all;

ENTITY DEMUX_GENERIC_TB IS
END DEMUX_GENERIC_TB;

constant WIDTH : integer := 2;
constant HEIGHT : integer := 8; -- => S input will be 3 bits wide

ARCHITECTURE tb OF DEMUX_GENERIC_TB IS
  signal a: std_logic_vector(WIDTH-1 DOWNTO 0);
  signal s: std_logic_vector(ceil_log2(HEIGHT)-1 downto 0);
  signal y: demux_generic_output(HEIGHT-1 downto 0, WIDTH-1 downto 0);
BEGIN

  process
  begin

      a <= (others => 1);
      s <= "000";
      wait for 20 ns;

      a <= (others => 1);
      s <= "001";
      wait for 20 ns;

      a <= (others => 1);
      s <= "010";
      wait for 20 ns;

      a <= (others => 1);
      s <= "011";
      wait for 20 ns;

      a <= (others => 1);
      s <= "100";
      wait for 20 ns;

      a <= (others => 1);
      s <= "101";
      wait for 20 ns;

      a <= (others => 1);
      s <= "110";
      wait for 20 ns;

      a <= (others => 1);
      s <= "111";
      wait for 20 ns;

      a <= (others => 1);
      s <= "010";
      wait;

  end process;


  dut: ENTITY work.DEMUX_GENERIC
                  GENERIC MAP(WIDTH<=WIDTH,
                              HEIGHT<=HEIGHT)
                  PORT MAP(
                           A<=A,
                           S<=S,
                           Y<=Y);
END ARCHITECTURE;
