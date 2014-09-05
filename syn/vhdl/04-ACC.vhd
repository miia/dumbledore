library IEEE;
use IEEE.std_logic_1164.all; 
use IEEE.std_logic_unsigned.all;

entity ACC is
    Generic (
	    WIDTH : integer := 8
	);
	Port (	A:	In	std_logic_vector(WIDTH-1 downto 0);
		B:	In	std_logic_vector(WIDTH-1 downto 0);
		CK:	In	std_logic;
		RESET:	In	std_logic;
		accumulate:	In	std_logic;
		acc_enable:	In	std_logic;
		Y:	Out	std_logic_vector(WIDTH-1 downto 0));
end ACC;


architecture Structural of ACC is

signal n, out_add, feed_back : std_logic_vector(WIDTH-1 downto 0);
signal reg_clk: std_logic;
signal acc_en_n: std_logic;     --active-low enable signal for register
signal accumulate_n: std_logic; --selection signal for mux
signal clk_gated: std_logic;

begin
    
reg_clk <= CK;
accumulate_n <= accumulate;
    
acc_en_n <= not acc_enable; --NOTE: acc_enable is active-low
clk_gated <= reg_clk and acc_en_n; --register can change value only if acc_en_n is '1' (acc_en is '0')
Y <= feed_back; --connect feedback and Y signals

mux0 : ENTITY work.MUX21_GENERIC
    generic map(
	    WIDTH => WIDTH --second WIDTH is taken from ACC generic
	)
	port map(
	   A => n,
		B => B,
		S => accumulate,
		Y => out_add
	);
	
add0 : entity work.RCA(structural)
    generic map(
	    WIDTH => WIDTH
	)
	port map(
	    A => A,
		B => feed_back,
		Ci => '0',
		S => n,
		Co => OPEN
	);
	   
reg0 : ENTITY work.REG_GENERIC
    generic map(
	    WIDTH => WIDTH
	)
	port map(
	   D => out_add,
		CK => clk_gated, --register can change value only if acc_en_n is '1' (acc_enable is '')
		RESET => RESET,
		Q => feed_back
	);
end Structural;
