library IEEE;
use IEEE.std_logic_1164.all; --  libreria IEEE con definizione tipi standard logic

entity MUX21_GENERIC is
	Generic(
		WIDTH: 	integer:=1
		);
	Port (	A:	In	std_logic_vector(WIDTH-1 DOWNTO 0);
		B:	In	std_logic_vector(WIDTH-1 DOWNTO 0);
		S:	In	std_logic;
		Y:	Out	std_logic_vector(WIDTH-1 DOWNTO 0)
	);
end MUX21_GENERIC;

architecture STRUCTURAL of MUX21_GENERIC is

	signal Y1: std_logic_vector(WIDTH-1 DOWNTO 0);
	signal Y2: std_logic_vector(WIDTH-1 DOWNTO 0);
	signal SB: std_logic;

	component ND2
	
	Port (	A:	In	std_logic;
		B:	In	std_logic;
		Y:	Out	std_logic);
	end component;
	
	component IV
	
	Port (	A:	In	std_logic;
		Y:	Out	std_logic);
	end component;

begin

	generate_mux: for i in 0 to WIDTH-1 generate
		UIV : IV
		Port Map ( S, SB);
	
		UND1 : ND2
		Port Map ( A(i), S, Y1(i));     --with input S=1, A gets out of the mux. thanks NAND!
	
		UND2 : ND2
		Port Map ( B(i), SB, Y2(i));    --with input S=0, B gets out of the mux. thanks NAND!
	
		UND3 : ND2
		Port Map ( Y1(i), Y2(i), Y(i));
	end generate;


end STRUCTURAL;
