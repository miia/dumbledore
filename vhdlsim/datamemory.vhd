library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use IEEE.math_real.all; --contains "ceil" function that is used during generics mapping
use WORK.all;
use work.ceillog.all;

entity data_memory is
 generic ( NREGS:          integer := 32;
           REG_WIDTH:      integer := 64);
 port ( CLK: 		IN std_logic;
         RESET: 	IN std_logic;
	 ENABLE: 	IN std_logic;
	 RD1: 		IN std_logic;
	 WR: 		IN std_logic;
	 ADD_WR: 	IN std_logic_vector(( ceil_log2(NREGS))-1 downto 0);
	 ADD_RD1: 	IN std_logic_vector(( ceil_log2(NREGS))-1 downto 0);
	 DATAIN: 	IN std_logic_vector(REG_WIDTH-1 downto 0);
    OUT1: 		OUT std_logic_vector(REG_WIDTH-1 downto 0) := (others=>'0'));
end data_memory;

architecture A of data_memory is

        -- suggested structures
        subtype REG_ADDR is natural range 0 to 31; -- using natural type (from now on, REG_ADDR is equivalent to "(0 to 31)")
	type REG_ARRAY is array(REG_ADDR) of std_logic_vector(REG_WIDTH-1 downto 0); -- we'll use REG_WIDTH=64
--	signal REGISTERS : REG_ARRAY; 
	
begin 
 
process (CLK)
variable REGISTERS : REG_ARRAY; --declared as VARIABLE instead of signal; in this way, if both a write and a read are performed on the same register at the same time, write can take precedence over read (in the same cycle, the stored value will be updated, and the output value will be the updated one) 
begin

  if (CLK='1' and CLK'event) then
      
    OUT1 <= (others=>'0'); --first of all, assign all 0's to outputs at each new clock cycle (default output behavior)
    
    if (RESET='1') then
        REGISTERS(REG_ADDR) := (others=>(others=>'0')); --reset content of ALL registers
        --OUT1 <= (others=>'0'); --reset outputs as well
        --OUT2 <= (others=>'0');
    else
        if (ENABLE='1') then
            if (WR='1') then --WRITE HAS PRIORITY over read operations.
                REGISTERS(to_integer(unsigned(ADD_WR))):=DATAIN;  --write has been requested, enable is high, reset is not active.
            end if;
            if (RD1='1') then
                OUT1<=REGISTERS(to_integer(unsigned(ADD_RD1)));  --read on port 1 has been requested, enable is high, reset is not active.
            end if;
        end if;
    end if;
  end if;
end process;

end A;

----


configuration CFG_RF_BEH of data_memory is
  for A
  end for;
end configuration;
