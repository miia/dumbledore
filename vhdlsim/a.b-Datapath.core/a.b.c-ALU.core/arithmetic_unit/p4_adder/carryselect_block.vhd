library ieee; 
use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all;

entity carryselect_block is 
	generic (WIDTH: integer := 4);
	Port (	A:	In	std_logic_vector(WIDTH-1 downto 0);
		B:	In	std_logic_vector(WIDTH-1 downto 0);
		Ci_ACTUAL:	In	std_logic;
		S:	Out	std_logic_vector(WIDTH-1 downto 0);
    Cout: Out std_logic
--no Cout signal: each of these CS blocks will take its Cin from outside (the sparse-tree carry generator), so no block needs to generate a carry-out for the next one.
		);
end carryselect_block; 

architecture STRUCTURAL of carryselect_block is

	

	signal sum_from_rca0, sum_from_rca1 : std_logic_vector(WIDTH-1 downto 0);
  signal cout_from_rca0, cout_from_rca1: std_logic;
  signal out_from_rca0: std_logic_vector(WIDTH downto 0);
  signal out_from_rca1: std_logic_vector(WIDTH downto 0);
  signal out_from_mux: std_logic_vector(WIDTH downto 0);
	begin --start of actual architecture
	
   out_from_rca0 <= cout_from_rca0 & sum_from_rca0;
   out_from_rca1 <= cout_from_rca1 & sum_from_rca1;
   S <= out_from_mux(WIDTH-1 downto 0);
   Cout <= out_from_mux(WIDTH);
   
	rca_0: ENTITY work.RCA generic map(WIDTH => WIDTH)
	port map( A=> A,
		  B => B,
		  Ci => '0',
		  S => sum_from_rca0,
		  Co => cout_from_rca0
	);  

	rca_1: ENTITY work.RCA generic map(WIDTH => WIDTH)
	port map( A=> A,
		  B => B,
		  Ci => '1',
		  S => sum_from_rca1,
		  Co => cout_from_rca1
	);  	

	mux_sum_out: ENTITY work.MUX21_GENERIC
  generic map(WIDTH => WIDTH+1)
	port map( A=> out_from_rca1,
		  B => out_from_rca0,
		  S => Ci_ACTUAL,
		  Y => out_from_mux
	); 

end STRUCTURAL;
