LIBRARY IEEE;
USE IEEE.std_logic_1164.all;

ENTITY LOADHIGH IS
  GENERIC(WIDTH: integer := 16);
  PORT(A: in std_logic_vector(WIDTH-1 downto 0);
  Y: out std_logic_vector(2*WIDTH-1 downto 0)
);
END LOADHIGH;

ARCHITECTURE structural of LOADHIGH IS
BEGIN
  Y(2*WIDTH-1 downto WIDTH) <= A;
  Y(WIDTH-1 downto 0) <= (OTHERS => '0');
END ARCHITECTURE;
