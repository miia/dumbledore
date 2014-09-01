 
library IEEE;
use IEEE.std_logic_1164.all;
--use IEEE.std_logic_arith.all;
--use IEEE.std_logic_unsigned.all;
use WORK.all;

entity IMM_EXTENDER is
	port(	INPUT: in std_logic_vector(15 downto 0); --16-bit immediate value to be extended.
		SIGN: in std_logic;	-- 1 = perform signed extension; 0 = unsigned extension (pad with zeroes)
		OUTPUT: out std_logic_vector(31 downto 0) --extended output.
	);

end entity IMM_EXTENDER;


architecture DATAFLOW of IMM_EXTENDER is

signal output_low : std_logic_vector(15 downto 0); 
signal output_high: std_logic_vector(15 downto 0);

begin

   --LOW HALF:
   --hard-wire immediate value to low part of output:
   output_low <= INPUT;
   OUTPUT(15 downto 0) <= output_low;

   --HIGH HALF:
   output_high <= (others=>'0') when SIGN='0'--if unsigned extension, pad with zeroes;
             else (others=>INPUT(15));       --else, replicate MSB of input.
   OUTPUT(31 downto 16) <= output_high;

end architecture DATAFLOW;




