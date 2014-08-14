library IEEE;
use IEEE.std_logic_1164.all;
--use IEEE.std_logic_arith.all;
--use IEEE.std_logic_unsigned.all;

use WORK.all;
--use WORK.ceillog.all;

-----------------------------------------------------------------------------------------------------------------
--Receives the result coming from the Arithmetic Unit (after it has performed signed or unsigned subtraction); --
--based on this result, it can tell you whether one of the following is true: A<B, A<=B, A=B, A>=B, or A>B.    --
--e.g.: to implement sgteu, first perform unsigned subtraction with the arith unit, then configure this for >=.--
-----------------------------------------------------------------------------------------------------------------

entity COMPARATOR_GENERIC is
	generic(N: integer);
	port(	INPUT: in std_logic_vector(N-1 downto 0); --result coming from Arithmetic unit output.
		WHAT_TO_CHECK: in std_logic(2 downto 0);	-- see the CASE statement below for instructions; there are 5 choices possible => 3 bits.
		OUTPUT: out std_logic_vector(N-1 downto 0) --generates an output of the same width as the input data, since this output will be fed into a register too.
	);

end entity COMPARATOR_GENERIC;


architecture BEHAVIORAL of COMPARATOR_GENERIC is

signal msb : std_logic_vector; 
signal zero: std_logic_vector;

--signal results: std_logic_vector(4 downto 0); --from left to right, the bits represent whether: A<B, A<=B, A=B, A>=B, A>B.
--signal output_tmp: std_logic_vector(N-1 downto 0);

begin

        msb <= INPUT(N-1);
	zero <= "1" when INPUT = (others=>"0")
                    else "0";

        --output_tmp(N-1 downto 1) <= (others=>"0");
        output(N-1 downto 1) <= (others=>"0"); --all output bits except the LSB are hardwired to zero.

	COMP: process (INPUT, WHAT_TO_CHECK) is
	begin
		case sel is
		when  "000"  =>  output(0) <= msb;               -- A <  B
		when  "001"  =>  output(0) <= msb or zero;       -- A <= B
		when  "010"  =>  output(0) <= zero;              -- A =  B
		when  "011"  =>  output(0) <= not zero;          -- A != B
		when  "100"  =>  output(0) <= not msb;           -- A >= B
		when  "101"  =>  output(0) <= not (msb or zero); -- A >  B
		when others =>   output(0) <= "0"; --fallback
		end case;
	end process;

end architecture BEHAVIORAL;




