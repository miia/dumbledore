LIBRARY IEEE;
USE IEEE.std_logic_1164.all;
    
ENTITY ARITHMETIC_UNIT IS
  GENERIC(
  WIDTH: integer := 32
);

PORT(
  A: in std_logic_vector(WIDTH-1 downto 0);
  B: in std_logic_vector(WIDTH-1 downto 0);
  OP: in std_logic_vector(2 downto 0);
  Cout:  out std_logic;
  Y: out std_logic_vector(WIDTH-1 downto 0);
  Y_extended: out std_logic_vector(WIDTH-1 downto 0)
);
END ARITHMETIC_UNIT;

ARCHITECTURE structural OF ARITHMETIC_UNIT is
  signal addout, mulout, B_negated, B_sign: std_logic_vector(WIDTH-1 downto 0);
  signal mullongout: std_logic_vector(2*WIDTH-1 downto 0);
  signal Y_result: std_logic_vector(WIDTH-1 downto 0);
BEGIN
  --Manages difference between ADD and SUB
  --Last bit of OP makes difference in add/sub: if 1, Cin=1 and B=~B
  B_negated <= not B;

  addsub_mux: ENTITY work.MUX21_GENERIC
  GENERIC MAP(WIDTH => WIDTH) PORT MAP (A => B_negated, B => B, S => OP(0), Y => B_sign);

  adder: ENTITY work.P4_ADDER
  GENERIC MAP(WIDTH => WIDTH)
  PORT MAP(A => A, B => B_sign, S => addout, Cin => OP(0), Cout => Cout);

  boothmul: ENTITY work.BOOTHMUL
  GENERIC MAP(WIDTH => WIDTH)
  PORT MAP(A => A, B => B, OUTPUT => mullongout);
  mulout <= mullongout(WIDTH-1 downto 0);
  Y_extended <= mullongout(2*WIDTH-1 downto WIDTH);

  Y_result <= addout;

  bypassmux: ENTITY work.MUX21_GENERIC
  GENERIC MAP(WIDTH => WIDTH)
  PORT MAP(A => A, B => Y_result, S => OP(2), Y => Y);

END ARCHITECTURE;


