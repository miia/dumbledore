LIBRARY IEEE;
use IEEE.std_logic_1164.ALL;
use IEEE.numeric_std.ALL;
use work.myTypes.ALL;

ENTITY MEMORY_STAGE IS
  PORT(
    CLK: in std_logic;
    RESET: in std_logic; -- Active low
    ADDR: in std_logic_vector(DATA_ADDRESS_SIZE downto 0);
    RD_MEM: in std_logic;
    WR: 		IN std_logic;
    SIGN: in std_logic;
    LH: in std_logic;
    LB: in std_logic;
    DATA_IN: in std_logic_vector(31 downto 0);
    DATA_OUT: out std_logic_vector(31 downto 0)
  );
END MEMORY_STAGE;

ARCHITECTURE mixed OF MEMORY_STAGE IS
  constant REG_WIDTH: integer := 32;
  subtype REG_ADDR is natural range 0 to 1023; -- using natural type (from now on, REG_ADDR is equivalent to "(0 to 31)")
	type REG_ARRAY is array(REG_ADDR) of std_logic_vector(REG_WIDTH-1 downto 0); -- we'll use REG_WIDTH=64
  signal REGISTERS : REG_ARRAY; -- No contemporary LOAD and STORE will be done in memory
  signal ADDRESS_OF_REG: DATA_ADDRESS_STRETCHED;
  signal MEMOUT: std_logic_vector(31 downto 0);
  signal D32, hword_ext, the_read_result: std_logic_vector(31 downto 0);
  signal D16, byte_ex, hword: std_logic_vector(15 downto 0);
  signal D8: std_logic_vector(7 downto 0);
  signal toextendByte, toextendHword: std_logic;
BEGIN

  ADDRESS_OF_REG <= ADDR(31 downto 2); -- Last 2 bits decide HW or B

  process (CLK, RESET)
  begin
  if (RESET='0') then
      REGISTERS(REG_ADDR) <= (others=>(others=>'0')); --reset content of ALL registers
  else
    if (CLK='1' and CLK'event) then 
      MEMOUT <= (others=>'0'); --first of all, assign all 0's to outputs at each new clock cycle (default output behavior) 
      if (WR='1') then --WRITE HAS PRIORITY over read operations.
        -- Store operation: we can store a word, or a hw, or a byte
        if (LH='0' and LB='0') then
          REGISTERS(to_integer(unsigned(ADDRESS_OF_REG)))<=DATA_IN;  --Write a Word
        elsif (LH='1' and LB='0') then
          if(ADDR(1)='1') then
            --Load high half-word
            REGISTERS(to_integer(unsigned(ADDRESS_OF_REG)))<=DATA_IN(15 downto 0) & REGISTERS(to_integer(unsigned(ADDRESS_OF_REG)))(15 downto 0);
          else
            --Load low half-word
            REGISTERS(to_integer(unsigned(ADDRESS_OF_REG)))<= REGISTERS(to_integer(unsigned(ADDRESS_OF_REG)))(31 downto 16) & DATA_IN(15 downto 0) ;
          end if;
        else
          --Load a byte (this includes also case LH=0, LB=1 to cover all possible cases)
          if(ADDR(1 downto 0)="00") then
            --Byte 0
            REGISTERS(to_integer(unsigned(ADDRESS_OF_REG)))<=REGISTERS(to_integer(unsigned(ADDRESS_OF_REG)))(31 downto 8) & DATA_IN(7 downto 0);
          elsif(ADDR(1 downto 0)="01") then
            REGISTERS(to_integer(unsigned(ADDRESS_OF_REG)))<=REGISTERS(to_integer(unsigned(ADDRESS_OF_REG)))(31 downto 16) & DATA_IN(7 downto 0) & REGISTERS(to_integer(unsigned(ADDRESS_OF_REG)))(7 downto 0);
          elsif(ADDR(1 downto 0)="10") then
            REGISTERS(to_integer(unsigned(ADDRESS_OF_REG)))<=REGISTERS(to_integer(unsigned(ADDRESS_OF_REG)))(31 downto 24) & DATA_IN(7 downto 0) & REGISTERS(to_integer(unsigned(ADDRESS_OF_REG)))(15 downto 0);
          else
            REGISTERS(to_integer(unsigned(ADDRESS_OF_REG)))<= DATA_IN(7 downto 0) & REGISTERS(to_integer(unsigned(ADDRESS_OF_REG)))(23 downto 0);
          end if;
        end if;
      elsif(RD_MEM='1') then
        MEMOUT <= REGISTERS(to_integer(unsigned(ADDRESS_OF_REG)));
      end if;
    end if;
  end if;
end process;
      D32 <= MEMOUT;
      --Spills correct byte/hw/w from the word
      select_d16: entity work.MUX21_GENERIC 
      GENERIC MAP (WIDTH => 16) PORT MAP(A => MEMOUT(31 downto 16), B => MEMOUT(15 downto 0), S => ADDR(1), Y => D16);
      select_d8: entity work.MUX21_GENERIC 
      GENERIC MAP (WIDTH => 8) PORT MAP(A => D16(15 downto 8), B => D16(7 downto 0), S => ADDR(0), Y => D8);

      select_d8_extension: entity work.MUX21
      PORT MAP(A => D8(7), B => '0', S => SIGN, Y => toextendByte);
      --Sign extension for byte
      byte_ex(7 downto 0) <= D8;
      extend_d8: for i in 0 to 7 generate
        byte_ex(i+8) <= toextendByte;
      end generate; 

      select_correct_hw: entity work.MUX21_GENERIC
      GENERIC MAP(WIDTH => 16) PORT MAP(A => byte_ex, B => D16, S => LB, Y => hword);

      select_hw_extension: entity work.MUX21
      PORT MAP(A => hword(15), B => '0', S => SIGN, Y => toextendHword);
      --Sign extension for half word
      hword_ext(15 downto 0) <= hword;
      extend_hw: for i in 0 to 15 generate
        hword_ext(i+16) <= toextendHword;
      end generate; 

      select_result: entity work.MUX21_GENERIC
      GENERIC MAP(WIDTH => 32) PORT MAP(A => hword_ext, B => D32, S => LH, Y => the_read_result);
      DATA_OUT <= the_read_result;
end architecture;
