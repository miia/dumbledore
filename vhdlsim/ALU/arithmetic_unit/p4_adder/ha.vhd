library ieee; 
use ieee.std_logic_1164.all; 

entity HA is 

	Port (	A:	In	std_logic;
		B:	In	std_logic;
		--Ci:	In	std_logic;
		S:	Out	std_logic;
		Co:	Out	std_logic);
end HA; 

architecture BEHAVIORAL of FA is

begin

  -- S <= A xor B xor Ci after DFAS;
  S <= A xor B;
  -- Co <= (A and B) or (B and Ci) or (A and Ci) after DFAC;
  Co <= A and B;
  -- Co <= (A and B) or (B and Ci) or (A and Ci);
  
end BEHAVIORAL;

configuration CFG_FA_BEHAVIORAL of FA is	
  for BEHAVIORAL
  end for;
end CFG_FA_BEHAVIORAL;
