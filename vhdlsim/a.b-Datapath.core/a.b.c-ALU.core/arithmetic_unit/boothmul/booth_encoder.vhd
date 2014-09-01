library IEEE;
use IEEE.std_logic_1164.all;

ENTITY BOOTH_ENCODER IS
  PORT(
    Bim1: in std_logic; -- B(i-1);
    Bi: in std_logic; -- B(i);
    Bip1: in std_logic; -- B(i+1)
    Output: out std_logic_vector(2 downto 0)
  );
END BOOTH_ENCODER;


ARCHITECTURE behavioral OF BOOTH_ENCODER IS
    signal ins: std_logic_vector(2 downto 0);    
begin
    ins <= Bip1 & Bi & Bim1;
    process(ins) begin
     case ins is
              when  "000" => Output <= "000";
              when  "001" => Output <= "001";
              when  "010" => Output <= "001";
              when  "011" => Output <= "011";
              when  "100" => Output <= "100";
              when  "101" => Output <= "010";
              when  "110" => Output <= "010";
              when  "111" => Output <= "000";
              when others => Output <= "000";
      end case;
  end process;
end ARCHITECTURE;
