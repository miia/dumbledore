library ieee;
use ieee.std_logic_1164.ALL;

ENTITY P4_adder IS
	GENERIC(
		WIDTH: natural := 32
	);
	PORT(
		A: in std_logic_vector(WIDTH-1 DOWNTO 0); -- Should be a multiple of 4 or would work anyway?
		B: in std_logic_vector(WIDTH-1 DOWNTO 0);
		S: out std_logic_vector(WIDTH-1 DOWNTO 0);
		Cin: in std_logic;
		Cout: out std_logic
	);
END P4_adder;

ARCHITECTURE structural of P4_adder IS
	SIGNAL carries: std_logic_vector((WIDTH/4) downto 0); -- Delivers carries from generator to carryselect
BEGIN
    --We instantiate blocks of 4 bit
    cs: ENTITY work.carryselect_row 
      GENERIC MAP(
        CS_BLOCK_WIDTH => 4,
        CS_BLOCK_NUM=>WIDTH/4
      )
      PORT MAP(
        A => A(4*(WIDTH/4)-1 downto 0),
        B => B(4*(WIDTH/4)-1 downto 0),
        Ci_ACTUAL=>carries((WIDTH/4)-1 DOWNTO 0),
        S => S(4*(WIDTH/4)-1 downto 0)
      );

  cout_generation: if(WIDTH mod 4 = 0) generate
      Cout <= carries(WIDTH/4); -- Direct cout obtained by generator
  end generate;
  other_block: if(not (WIDTH mod 4 = 0)) generate
    -- Must add another cs at the end
    last_cs: ENTITY work.carryselect_block
      GENERIC MAP(
        WIDTH => WIDTH mod 4
      )
      PORT MAP(
        A => A(WIDTH-1 downto 4*(WIDTH/4)),
        B => B(WIDTH-1 downto 4*(WIDTH/4)),
        Ci_ACTUAL => carries(WIDTH/4),
        S => S(WIDTH-1 downto 4*(WIDTH/4)),
        Cout => Cout
      );
  end generate;

  -- Carry generator block
	cg: ENTITY work.carryGenerator 
		GENERIC MAP(
			SIZE => WIDTH
		)
		PORT MAP(
			Cin => Cin,
			A => A,
      B => B,
      OUTPUT => carries
    );

END ARCHITECTURE;
