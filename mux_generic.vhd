library IEEE;
use IEEE.std_logic_1164.all; --  libreria IEEE con definizione tipi standard logic
   
PACKAGE MUX_GENERIC_INPUT IS
  TYPE mux_generic_input IS ARRAY (NATURAL RANGE <>, NATURAL RANGE <>) OF STD_LOGIC;
END PACKAGE mux_generic_input;

use WORK.MUX_GENERIC_INPUT.all;
library IEEE;
use IEEE.std_logic_1164.all; --  libreria IEEE con definizione tipi standard logic
use IEEE.numeric_std.all;
use WORK.log2.all;
use WORK.constants.all; -- libreria WORK user-defined

entity MUX_GENERIC is
	Generic(
		WIDTH: 	integer:=1; -- number of bits
    HEIGHT: integer:=2 -- number of signals
		);
	Port (	A:	in mux_generic_input(HEIGHT-1 downto 0, WIDTH-1 downto 0); --In std_logic_vector(HEIGHT*WIDTH-1 DOWNTO 0);
		S:	In	std_logic_vector(log2_unsigned(HEIGHT)-1 downto 0);
		Y:	Out	std_logic_vector(WIDTH-1 DOWNTO 0)
	);
end MUX_GENERIC;

architecture BEHAVIORAL of MUX_GENERIC is

   constant size: integer := log2_unsigned( HEIGHT );

begin
   mux_process: process(A,S)
   variable n: natural;
   begin
       --n := to_integer(unsigned(S));
       --Y<=A(WIDTH*(n+1)-1 DOWNTO WIDTH*n);
     --This should be a std_logic_vector assignment, no comment
     assign_values: for i in 0 to WIDTH-1 loop
       Y(i)<=A(to_integer(unsigned(S)),i);
     end loop;
   end process;
end BEHAVIORAL;
