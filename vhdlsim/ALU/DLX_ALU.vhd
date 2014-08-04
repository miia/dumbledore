library IEEE;
use IEEE.std_logic_1164.all;
use work.myTypes.all;
use work.mux_generic_input.all;
use work.ceillog.all;

ENTITY DLX_ALU is
  PORT(
    OP: in ALUOP;
    A: in REGISTER_CONTENT;
    B: in REGISTER_CONTENT;
    Y: out REGISTER_CONTENT;
    FLAGS: out ALU_FLAGS;
    --Zero_flags: out std_logic;
    Y_extended: out REGISTER_CONTENT
);
END DLX_ALU;

ARCHITECTURE structural OF DLX_ALU is
  signal A_in, B_in, the_result, allatzero: REGISTER_CONTENT;
  signal shiftout, logicout, lhout, logiclhout, intout: REGISTER_CONTENT;
  signal opselection: MUX_GENERIC_INPUT(3 downto 0, REGISTER_SIZE-1 downto 0);
  signal mustchangetolh: std_logic;

begin
  A_in <= A;
  B_in <= B;

  arithUnit: ENTITY work.ARITHMETIC_UNIT
  GENERIC MAP(WIDTH => REGISTER_SIZE) PORT MAP(
  A => A_in, B => B_in, OP => OP(1 downto 0), Y => intout, Y_extended => Y_extended, Cout => FLAGS(0));

  logicUnit: ENTITY work.LOGIC_UNIT
  GENERIC MAP (N => REGISTER_SIZE) PORT MAP(A => A_in, B => B_in, FUNC => OP(1 downto 0), Y => logicout);

  loadHigh: ENTITY work.LOADHIGH
  GENERIC MAP(WIDTH => REGISTER_SIZE/2) PORT MAP(A => B_in(REGISTER_SIZE/2-1 downto 0), Y => lhout);

  --Selects between NOT and LH based on immediate type -- Bit 5 of operation, but only when op is xx11
  mustchangetolh <= OP(4) and OP(1) and OP(0);
  
  logiclhselector: ENTITY work.MUX21_GENERIC
  GENERIC MAP(WIDTH => REGISTER_SIZE) PORT MAP(A => lhout, B => logicout, S => mustchangetolh, Y => logiclhout);

  shifter: ENTITY work.SHIFTER_GENERIC
  GENERIC MAP(N => REGISTER_SIZE) PORT MAP 
  (A => A_in, B => B_in(ceil_log2(REGISTER_SIZE)-1 downto 0), LOGIC_ARITH => OP(2), LEFT_RIGHT => OP(0), SHIFT_ROTATE => OP(1), OUTPUT => shiftout);
  
  --This should be a std_logic_vector assignment, no comment
  assign_values_to_muxinput: for i in 0 to REGISTER_SIZE-1 generate
      opselection(0,i)<=intout(i);
      opselection(1,i)<=logiclhout(i);
      opselection(2,i)<=shiftout(i);
      opselection(3,i)<=shiftout(i);
  end generate;

  result_selector: ENTITY work.MUX_GENERIC
  GENERIC MAP(WIDTH => REGISTER_SIZE, HEIGHT => 4)
  PORT MAP(A => opselection, S => OP(3 downto 2), Y => the_result);

  Y <= the_result;

  allatzero <= (OTHERS => '0');
  process(the_result) begin
    IF (the_result=allatzero) THEN
      FLAGS(0) <= '1';
    ELSE
      FLAGS(0) <= '0';
    END IF;
  end process;

END ARCHITECTURE;
