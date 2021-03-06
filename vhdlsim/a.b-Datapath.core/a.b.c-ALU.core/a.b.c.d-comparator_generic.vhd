library IEEE;
use IEEE.std_logic_1164.all;
--use IEEE.std_logic_arith.all;
--use IEEE.std_logic_unsigned.all;

use WORK.all;
--use WORK.ceillog.all;

----------------------------------------------------------------------------------------------------------------------
--Receives the result coming from the Arithmetic Unit (after it has performed signed or unsigned subtraction, A-B); --
--based on this result, it can tell you whether one of the following is true: A<B, A<=B, A=B, A>=B, or A>B.         --
--e.g.: to implement sgteu, first perform unsigned subtraction with the arith unit, then configure this for >=.     --
----------------------------------------------------------------------------------------------------------------------

entity COMPARATOR_GENERIC is
	generic(N: integer);
	port(	INPUT: in std_logic_vector(N-1 downto 0); --result coming from Arithmetic unit output.
		WHAT_TO_CHECK: in std_logic_vector(3 downto 0);	-- see the CASE statement below for instructions; there are 5 choices possible on which condition to check => 3 bits are enough. Bit 3 switches signed/unsigned
		OUTPUT: out std_logic_vector(N-1 downto 0); --generates an output of the same width as the input data (since this output will be fed into a register too), but its value will be either 0 or 1.
		COUT: in std_logic
	);

end entity COMPARATOR_GENERIC;


architecture BEHAVIORAL of COMPARATOR_GENERIC is

signal msb : std_logic; 
signal zero: std_logic;
signal signed_comparison: std_logic;

signal all_zeroes : std_logic_vector(N-1 downto 0);

begin

    signed_comparison <= WHAT_TO_CHECK(3);
     --hard-wire A STRING OF ZEROES to an actual signal, just so we can use it to perform a comparison later:
     all_zeroes <= (others=>'0');
     
     
     msb  <= INPUT(N-1);
    zero <= '1' when INPUT = all_zeroes
              else '0';

     output(N-1 downto 1) <= (others=>'0'); --all output bits except the LSB are hardwired to zero.

    COMP: process (WHAT_TO_CHECK, msb, zero, signed_comparison) is
    begin
      if(signed_comparison='1') then
        case WHAT_TO_CHECK(2 downto 0) is
        when  "000"  =>  output(0) <= msb;               -- A <  B
        when  "001"  =>  output(0) <= msb or zero;       -- A <= B
        when  "010"  =>  output(0) <= zero;              -- A =  B
        when  "011"  =>  output(0) <= not zero;          -- A != B
        when  "100"  =>  output(0) <= not msb;           -- A >= B
        when  "101"  =>  output(0) <= not (msb or zero); -- A >  B
        when others =>   output(0) <= '0'; --fallback
        end case;
      else --Unsigned comparison
        case WHAT_TO_CHECK(2 downto 0) is
        when  "000"  =>  output(0) <= not COUT;               -- A <  B
        when  "001"  =>  output(0) <= (not COUT) or zero;       -- A <= B
        when  "010"  =>  output(0) <= COUT and zero;              -- A =  B
        when  "011"  =>  output(0) <= not (COUT and zero);          -- A != B
        when  "100"  =>  output(0) <= COUT;           -- A >= B
        when  "101"  =>  output(0) <= COUT and (not zero); -- A >  B
        when others =>   output(0) <= '0'; --fallback
        end case;
      end if;
    end process;

end architecture BEHAVIORAL;




