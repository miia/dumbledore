library ieee;
use ieee.std_logic_1164.ALL;

ENTITY pg IS
	PORT(
	Gik: IN std_logic;
	Pik: IN std_logic;
	Gk1j: IN std_logic;
	Pk1j: IN std_logic;
	Pout: OUT std_logic;
	Gout: OUT std_logic
	);
END pg;

ARCHITECTURE structural OF pg IS
BEGIN
	Pout<=Pik and Pk1j;
	Gout<=Gik or (Pik and Gk1j);
END ARCHITECTURE;
