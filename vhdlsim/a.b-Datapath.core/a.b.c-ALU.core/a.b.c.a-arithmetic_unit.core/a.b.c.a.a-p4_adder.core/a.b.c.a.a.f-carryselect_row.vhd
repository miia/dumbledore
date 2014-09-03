library ieee; 
use ieee.std_logic_1164.all; 
use ieee.std_logic_unsigned.all;

entity carryselect_row is 
	generic (CS_BLOCK_WIDTH: integer := 4;   --width for each of the carryselect_blocks (e.g.: 4 bits)
		 CS_BLOCK_NUM  : integer := 8);  --number of blocks to instantiate (using generate) (e.g.: 8 blocks total)
	Port (	A:	In	std_logic_vector(CS_BLOCK_WIDTH*CS_BLOCK_NUM-1 downto 0);
		B:	In	std_logic_vector(CS_BLOCK_WIDTH*CS_BLOCK_NUM-1 downto 0);
		Ci_ACTUAL:	In	std_logic_vector(CS_BLOCK_NUM-1 downto 0);
		S:	Out	std_logic_vector(CS_BLOCK_WIDTH*CS_BLOCK_NUM-1 downto 0)
		--Cout: out std_logic
--no Cout signal: each of the CS blocks will take its Cin from outside (the sparse-tree carry generator), so no block needs to generate a carry-out for the next one.
		);
end carryselect_row; 

architecture STRUCTURAL of carryselect_row is

	--component and signal declarations

	component carryselect_block is 
		generic (WIDTH: integer := 4);
		Port (	A:	In	std_logic_vector(WIDTH-1 downto 0);
			B:	In	std_logic_vector(WIDTH-1 downto 0);
			Ci_ACTUAL:	In	std_logic;
			S:	Out	std_logic_vector(WIDTH-1 downto 0);
			Cout: Out std_logic
	--no Cout signal: each of these CS blocks will take its Cin from outside (the sparse-tree carry generator), so no block needs to generate a carry-out for the next one.
      --EDIT: Cout 
		);
	end component; 
	
	--signal carries: std_logic_vector(CS_BLOCK_NUM-1 downto 0);

	begin --start of actual architecture
	
	gen_cs_block: for i in 0 to CS_BLOCK_NUM-1 generate --generate CS_BLOCK_NUM blocks, each having width CS_BLOCK_WIDTH
 
		cs_block_i: carryselect_block generic map(WIDTH => CS_BLOCK_WIDTH)
		port map( A=> A((i+1)*CS_BLOCK_WIDTH-1 downto i*CS_BLOCK_WIDTH),
			  B => B((i+1)*CS_BLOCK_WIDTH-1 downto i*CS_BLOCK_WIDTH),
			  Ci_ACTUAL => Ci_ACTUAL(i),
			  S => S((i+1)*CS_BLOCK_WIDTH-1 downto i*CS_BLOCK_WIDTH),
			  Cout => open
			  --Cout => carries(i)
		);  
	end generate;
	
	--Cout <= carries(CS_BLOCK_NUM-1);

end STRUCTURAL;
