library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all; --contains "ceil" function that is used during generics mapping
use WORK.all;
use work.ceillog.all;
use work.mux_generic_input.all;

entity register_file is
 generic ( NREGS:          integer := 32;
           REG_WIDTH:      integer := 64;
           SEND_REGISTER: boolean := true;
           TO_SEND: integer := 30);
 port ( CLK: 		IN std_logic;
         RESET: 	IN std_logic;
	 ENABLE: 	IN std_logic;
	 RD1: 		IN std_logic;
	 RD2: 		IN std_logic;
	 WR: 		IN std_logic;
	 ADD_WR: 	IN std_logic_vector(( ceil_log2(NREGS))-1 downto 0);
	 ADD_RD1: 	IN std_logic_vector(( ceil_log2(NREGS))-1 downto 0);
	 ADD_RD2: 	IN std_logic_vector(( ceil_log2(NREGS))-1 downto 0);
	 DATAIN: 	IN std_logic_vector(REG_WIDTH-1 downto 0);
    OUT1: 		OUT std_logic_vector(REG_WIDTH-1 downto 0) := (others=>'0');
	 OUT2: 		OUT std_logic_vector(REG_WIDTH-1 downto 0) := (others=>'0');
   REG_FIXED_OUT: OUT std_logic_vector(REG_WIDTH-1 downto 0)
	);
end register_file;

architecture A of register_file is

        -- suggested structures
  subtype REG_ADDR is natural range 0 to NREGS-1; -- using natural type (from now on, REG_ADDR is equivalent to "(0 to 31)") -- register 0 is reserved
	type REG_ARRAY is array(REG_ADDR) of std_logic_vector(REG_WIDTH-1 downto 0); -- we'll use REG_WIDTH=64
  signal theregs: REG_ARRAY; -- Debug purpose

begin 
 

  
process (CLK, RESET)
	variable REGISTERS : REG_ARRAY; --declared as VARIABLE instead of signal; in this way, if both a write and a read are performed on the same register at the same time, write can take precedence over read (in the same cycle, the stored value will be updated, and the output value will be the updated one) 
begin
    if (RESET='0') then
        REGISTERS(REG_ADDR) := (others=>(others=>'0')); --reset content of ALL registers
        REG_FIXED_OUT <= REGISTERS(TO_SEND); -- Use a register as output port
        theregs <= REGISTERS;
        --OUT1 <= (others=>'0'); --reset outputs as well
        --OUT2 <= (others=>'0');
    else
  if CLK'event AND CLK='1' then
    REGISTERS(0) := (OTHERS => '0');
      
    OUT1 <= (others=>'0'); --first of all, assign all 0's to outputs at each new clock cycle (default output behavior)
    OUT2 <= (others=>'0');
    
        if (ENABLE='1') then
            if (WR='1' and (to_integer(unsigned(ADD_WR)) > 0)) then --WRITE HAS PRIORITY over read operations.
                REGISTERS(to_integer(unsigned(ADD_WR))):=DATAIN;  --write has been requested, enable is high, reset is not active.
            end if;
            if (RD1='1') then
                OUT1<=REGISTERS(to_integer(unsigned(ADD_RD1)));  --read on port 1 has been requested, enable is high, reset is not active.
            end if;
            if (RD2='1') then
                OUT2<=REGISTERS(to_integer(unsigned(ADD_RD2)));  --read on port 2 has been requested, enable is high, reset is not active.
            end if;
        end if;
    end if;
  end if;
  --end generate;
end process;

end A;

----

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use WORK.all;
use work.ceillog.all;
use work.myTypes.all;
use work.mux_generic_input.all;

ARCHITECTURE structural OF register_file IS
  subtype REG_ADDR is natural range 0 to NREGS-1; -- using natural type (from now on, REG_ADDR is equivalent to "(0 to 31)") -- register 0 is reserved
	type REG_ARRAY is array(REG_ADDR) of std_logic_vector(REG_WIDTH-1 downto 0); -- we'll use REG_WIDTH=64
  signal theregs: REG_ARRAY; -- Debug purpose
  signal enables: std_logic_vector(REG_ADDR);
  signal input_muxes: mux_generic_input(NREGS-1 downto 0, REG_WIDTH-1 downto 0);
BEGIN
  demuxer: process(ADD_WR, WR) begin -- Enables the register for writing
    enables <= (OTHERS => '1');
    enables(to_integer(unsigned(ADD_WR))) <= '0' or (not WR) ; -- If WR='0', enable forced to 1 (enable is active-low)
  end process;

  theregs(0) <= (OTHERS => '0'); -- R0 can't be written and is hard-wired
  gen_registers: for i in 1 to NREGS-1 generate
    regN: entity work.REG_GENERIC_ENABLED
    GENERIC MAP(WIDTH => REG_WIDTH) PORT MAP(CK => CLK, RESET => RESET, D => DATAIN, Q => theregs(i), ENABLE => enables(i));
  end generate;

  gen_input_muxes: for i in REG_ADDR generate
    inner_gen: for j in 0 to REG_WIDTH-1 generate
      input_muxes(i,j) <= theregs(i)(j);
    end generate;
  end generate;

  RD1_MUX: ENTITY work.MUX_GENERIC
  GENERIC MAP(WIDTH => REG_WIDTH, HEIGHT => NREGS) PORT MAP(A => input_muxes, S => ADD_RD1, Y => OUT1);

  RD2_MUX: ENTITY work.MUX_GENERIC
  GENERIC MAP(WIDTH => REG_WIDTH, HEIGHT => NREGS) PORT MAP(A => input_muxes, S => ADD_RD2, Y => OUT2);
END ARCHITECTURE;

