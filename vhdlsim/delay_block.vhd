LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;

--This entity is a concatenation of 1 or more registers (used to make a good delay on some data)
ENTITY DELAY_BLOCK IS
  GENERIC(WIDTH : integer := 32;
    NREGS : integer := 1
  );
  PORT(CLK : in std_logic;
  RESET: in std_logic;
  D: in std_logic_vector(WIDTH-1 downto 0);
  Q: out std_logic_vector(WIDTH-1 downto 0)
);

END ENTITY;

ARCHITECTURE structural OF DELAY_BLOCK IS
  type ensamble is ARRAY(NREGS downto 0) OF std_logic_vector(WIDTH-1 downto 0);
  signal the_signals: ensamble;
BEGIN
  the_registers: for i in 0 to NREGS-1 generate
    regI: ENTITY work.REG_GENERIC
    GENERIC MAP(WIDTH => WIDTH) PORT MAP(CK => CLK, RESET => RESET, D => the_signals(i), Q => the_signals(i+1));
  end generate;
  Q <= the_signals(NREGS);
  the_signals(0) <= D;
END ARCHITECTURE;
