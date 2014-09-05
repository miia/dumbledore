library IEEE;
use IEEE.std_logic_1164.all; 

entity REG_GENERIC is
  Generic (
            WIDTH : integer := 8
          );
  Port (	D:	In	std_logic_vector(WIDTH-1 downto 0);
         CK:	In	std_logic;
         RESET:	In	std_logic;
         Q:	Out	std_logic_vector(WIDTH-1 downto 0));
end REG_GENERIC;


architecture PIPPO of REG_GENERIC is -- flip flop D with syncronous reset

begin
  PSYNCH: process(CK,RESET)
  begin
    if RESET='0' then -- active low reset 
      Q <= (OTHERS => '0');
    else
      if CK'event and CK='1' then -- positive edge triggered:
        Q <= D; -- input is written on output
      end if;
    end if;
  end process;

end PIPPO;
