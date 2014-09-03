library ieee;
use ieee.std_logic_1164.all;

ENTITY generator IS
	PORT(
	Gik: IN std_logic;
	Pik: IN std_logic;
	Gk1j: IN std_logic;
	Gout: OUT std_logic
	);
END GENERATOR;

ARCHITECTURE structural OF generator IS
BEGIN
	Gout<= Gik or(Pik and Gk1j);
END ARCHITECTURE;
