ENTITY TB_MEMORY_STAGE IS
END ENTITY;

ARCHITECTURE test OF TB_MEMORY_STAGE IS
    signal CLK:  std_logic := '0' ;
    signal RESET: std_logic := '0' ; -- Active low
    signal ADDR:  std_logic_vector(DATA_ADDRESS_SIZE downto 0);
    signal RD_MEM:  std_logic;
    signal WR: std_logic;
    signal SIGN:  std_logic;
    signal LH:  std_logic;
    signal LB:  std_logic
    signal DATA_IN:  std_logic_vector(31 downto 0);
    signal DATA_OUT: std_logic_vector(31 downto 0);
BEGIN
  toTest: entity work.MEMORY_STAGE
  PORT MAP(CLK => CLK, RESET => RESET; ADDR => ADDR, RD_MEM => RD_MEM, WR => WR, SIGN => SIGN, LH => LH, LB => LB, DATA_IN => DATA_IN, DATA_OUT => DATA_OUT);

  CLK <= not CLK after 10 ns;

  process begin
    RESET <= '0';
    ADDR <= (OTHERS => '0');
    LH <= '0';
    LB <= '0';
    RD_MEM <= '0';
    WR <= '0';
    DATA_IN <= (OTHERS => '0');
    wait for 5 ns;
    RESET <= '1';
    wait for 40 ns;
    -- Write a B to 0x01
    ADDR(0) <= '1';
    WR <= '1';
    LB <= '1';
    LH <= '1';
    DATAIN(7 downto 0) <= "10101010";
    wait for 20 ns;
    -- Hw to 0x02
    ADDR(1 downto 0) <= "10";
    LB <= '0';
    DATAIN(15 downto 0) <= "1111000000001111";
    wait for 20 ns;
    -- Read a W from 0
    ADDR(1 downto 0) <= "00";
    LH <= '0';
    WR <= '0';
    RD_MEM <= '1';
    wait for 20 ns;
    -- Read from x04
    ADDR(2) <= '1';
    wait for 20 ns;
    -- Read HW with sign
    SIGN <= '1';
    LH <= '1';
    ADDR(2 downto 0) <= "010"
    wait for 20 ns;
    --Read Byte with sign
    ADDR(0) <= '1';
    LB <= '1';
    wait for 20 ns;
    ADDR(1) <= '0';
    wait for 20 ns;
    wait;
  end process;
END ARCHITECTURE;

