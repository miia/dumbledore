--DEMULTIPLEXER:
--has a single WIDTH-bits input;
--and HEIGHT outputs (each WIDTH-bits wide).
--forwards the input to ONLY ONE of the WIDTH-bit outputs, depending on the value of the selection signal.

library IEEE;
use IEEE.std_logic_1164.all; --  libreria IEEE con definizione tipi standard logic

PACKAGE DEMUX_GENERIC_OUTPUT IS
  TYPE demux_generic_output IS ARRAY (NATURAL RANGE <>, NATURAL RANGE <>) OF STD_LOGIC;
END PACKAGE demux_generic_output;

use WORK.DEMUX_GENERIC_OUTPUT.all;
library IEEE;
use IEEE.std_logic_1164.all; --  libreria IEEE con definizione tipi standard logic
use IEEE.numeric_std.all;
use WORK.ceillog.all;

entity DEMUX_GENERIC is
	Generic(
		WIDTH: 	integer:=1; -- number of bits
        HEIGHT: integer:=2 -- number of signals
		);
	Port (	
        A:	in	std_logic_vector(WIDTH-1 DOWNTO 0);  --WIDTH-bits input
		  S:	in	std_logic_vector(ceil_log2(HEIGHT)-1 downto 0);   --selection signal (ceil(log2(HEIGHT)) bits wide)
        Y:	out demux_generic_output(HEIGHT-1 downto 0, WIDTH-1 downto 0) --just ONE of these WIDTH-1 wide outputs will be driven at a time; the others will be pulled down to 0.
	);
end DEMUX_GENERIC;

architecture BEHAVIORAL of DEMUX_GENERIC is

   constant size: integer := ceil_log2( HEIGHT );

begin
   demux_process: process(A,S)
   variable n: natural;
   begin

     pull_down_1:for i in HEIGHT-1 downto 0 loop
         pull_down_2:for j in WIDTH-1 downto 0 loop
             Y(i, j) <= '0'; --default assignment: all outputs are zero.
         end loop;     
     end loop;
 
     assign_values: for i in 0 to WIDTH-1 loop  --drive only the selected output with the input value.
         Y(to_integer(unsigned(S)),i)<=A(i);
     end loop;

   end process;
end BEHAVIORAL;
