 
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use work.myTypes.all;

use work.ceillog.all;

entity tb_IRAM is
end tb_IRAM;

architecture Behavioral of tb_IRAM is

    constant RAM_DEPTH : integer := 48;   --configure accordingly to the ones used in the DUT
    constant ADDR_LEN  : integer := ceil_log2(RAM_DEPTH);
    constant I_SIZE :    integer := 32;

    signal Rst: std_logic := '0'; --start with reset active
    signal Addr: std_logic_vector(ADDR_LEN-1 downto 0) := (others=>'0');
    signal Dout: std_logic_vector(I_SIZE-1 downto 0);

    signal CLK: std_logic := '0';  --a fictitious clock signal, just to help picture the external program counter reading data from here


begin

        CLK <= not CLK after 2 ns;

        -- instance of IRAM
        dut: ENTITY work.IRAM(IRam_Beh)
        generic map (
               RAM_DEPTH => RAM_DEPTH,
               I_SIZE    => I_SIZE
               )
        port map (
               Rst  => Rst,
               Addr => Addr,
               Dout => Dout
               );

	Rst <= '0', '1' after 3 ns;    --hold reset active for first 3 ns

        CONTROL: process
        variable i : integer := 0;
        begin

          wait for 6 ns;

          SCAN_ALL_IRAM: for i in 0 to RAM_DEPTH loop
  	      Addr <= conv_std_logic_vector(i,ADDR_LEN);
              wait for 2*2 ns;
          end loop;

          wait;

        end process;

end Behavioral;
