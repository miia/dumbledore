library ieee;
use ieee.std_logic_1164.all;

ENTITY pg_network IS
	GENERIC(
		SIZE: natural
	);
	PORT(
	A: IN std_logic_vector(SIZE-1 downto 0);
	B: IN std_logic_vector(SIZE-1 downto 0);
	Cin: IN std_logic;
	Pout: OUT std_logic_vector(SIZE-1 downto 0);
	Gout: OUT std_logic_vector(SIZE-1 downto 0)
	);
END pg_network;

ARCHITECTURE structural OF pg_network IS
BEGIN
	Pout<=A xor B;
	Gout(SIZE-1 downto 1) <= A(SIZE-1 downto 1) and B(SIZE-1 downto 1);
	--Generate also G1:0 as G1 + P1xCin
	Gout(0) <= (A(0) and B(0)) or ((A(0) xor B(0)) and Cin);
END ARCHITECTURE;
