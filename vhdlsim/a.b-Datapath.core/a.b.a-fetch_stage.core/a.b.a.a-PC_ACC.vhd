library IEEE;
use IEEE.std_logic_1164.all; 
use IEEE.std_logic_unsigned.all;

entity PC_ACC is
    Generic (
	    WIDTH : integer := 26
	);
	Port (IMMEDIATE:	In	std_logic_vector(WIDTH-1 downto 0);
    NEW_VALUE:	In	std_logic_vector(WIDTH-1 downto 0);
		CLK:	In	std_logic;
		RESET:	In	std_logic;
    ACC_ENABLE: In std_logic; -- Active low
		ACC_JMP:	In	std_logic;
		OVERWRITE:	In	std_logic;
		Y:	Out	std_logic_vector(WIDTH-1 downto 0));
end PC_ACC;

architecture Structural of PC_ACC is

signal n, out_add, feed_back, out_mux_pred,out_mux_overwrite : std_logic_vector(WIDTH-1 downto 0);
signal clk_gated: std_logic;

begin
    
--clk_gated <= CLK and (not ACC_ENABLE); --register can change value only if acc_en_n is '1' (acc_en is '0')
Y <= feed_back; --connect feedback and Y signals

-- Ci <= 1, so PC=PC+1+imm or PC=PC+1+0; as code addresses are always *4, PC=PC+4+imm of PC=PC+4+0
add_to_pc: ENTITY work.p4_adder
GENERIC MAP( WIDTH => WIDTH ) PORT MAP(A => out_mux_pred, B => feed_back, Cin => '1', S => out_add, Cout => OPEN);

mux_pred : ENTITY work.MUX21_GENERIC
  generic map(
	    WIDTH => WIDTH --second WIDTH is taken from PC_ACC generic
	)
	port map(
		A => IMMEDIATE,
	  B => (OTHERS => '0'),
		S => ACC_JMP,
		Y => out_mux_pred
	);
	
mux_overwrite : ENTITY work.MUX21_GENERIC
  generic map(
	    WIDTH => WIDTH --second WIDTH is taken from PC_ACC generic
	)
	port map(
	  A => NEW_VALUE,
		B => out_add,
		S => OVERWRITE,
		Y => out_mux_overwrite
	);
	
	   
reg_pc : ENTITY work.REG_GENERIC_ENABLED
  generic map(
	  WIDTH => WIDTH
	)
	port map(
	  D => out_mux_overwrite,
		CK => CLK, --register can change value only if acc_en_n is '1' (acc_enable is active low)
		RESET => RESET,
    ENABLE => ACC_ENABLE,
		Q => feed_back
	);
	
end Structural;
