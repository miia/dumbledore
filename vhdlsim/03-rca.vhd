library ieee; 
use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all;

entity RCA is 
	generic (WIDTH: integer := 8);
	Port (	A:	In	std_logic_vector(WIDTH-1 downto 0);
		B:	In	std_logic_vector(WIDTH-1 downto 0);
		Ci:	In	std_logic;
		S:	Out	std_logic_vector(WIDTH-1 downto 0);
		Co:	Out	std_logic);
end RCA; 

architecture STRUCTURAL of RCA is

  signal STMP : std_logic_vector(WIDTH-1 downto 0);
  signal CTMP : std_logic_vector(WIDTH downto 0);

begin

  CTMP(0) <= Ci;
  S <= STMP;
  Co <= CTMP(WIDTH);
  
  ADDER1: for I in 1 to WIDTH generate
    FAI : ENTITY work.FA 
	  Port Map (A(I-1), B(I-1), CTMP(I-1), STMP(I-1), CTMP(I)); 
  end generate;

end STRUCTURAL;

