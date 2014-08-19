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
    --Zero_flags: out std_logic;
    Y_extended: out REGISTER_CONTENT
);
END DLX_ALU;

-----------------------------------------------------------------------------------------------------------------------------------------------------
--ALUOP INPUT:																	   --
--6 bits (5 downto 0);																   --
--																		   --
--bits 8 downto 6 = configure comparator (can't use bits 2 downto 0 for this, as it needs to be used at the same time as the arithmetic unit.)     --
--bit  5 = drive a little mux21 to pre-select between logic unit output or LH output (before getting to the big 4-input mux)			   --
--bits 4 downto 3 = drive the big output mux: "00"=>arith unit output; "01"=>LH/logic unit output; "10"=>shifter output; "11"=>comparator output.  --
--bit  2 downto 0 = configure the currently selected functional unit (arithmetic/logic/LH/shift/compare block).					   --
-----------------------------------------------------------------------------------------------------------------------------------------------------


ARCHITECTURE structural OF DLX_ALU is
  signal A_in, B_in, the_result, allatzero: REGISTER_CONTENT;
  signal shiftout, compout, logicout, lhout, logiclhout, intout: REGISTER_CONTENT;
  signal opselection: MUX_GENERIC_INPUT(3 downto 0, REGISTER_SIZE-1 downto 0);
  signal mustchangetolh: std_logic;
  signal FLAGS: ALU_FLAGS;

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
  mustchangetolh <= OP(5) and OP(1) and OP(0);
  
  logiclhselector: ENTITY work.MUX21_GENERIC
  GENERIC MAP(WIDTH => REGISTER_SIZE) PORT MAP(A => lhout, B => logicout, S => mustchangetolh, Y => logiclhout);

  shifter: ENTITY work.SHIFTER_GENERIC
  GENERIC MAP(N => REGISTER_SIZE) PORT MAP 
  (A => A_in, B => B_in(ceil_log2(REGISTER_SIZE)-1 downto 0), LOGIC_ARITH => OP(2), LEFT_RIGHT => OP(0), SHIFT_ROTATE => OP(1), OUTPUT => shiftout);

  comparator: ENTITY work.COMPARATOR_GENERIC  --receives output of arithmetic unit, and performs checks on it (under the assumption that A-B has just been computed)
  GENERIC MAP(N => REGISTER_SIZE) PORT MAP 
  (INPUT => intout, WHAT_TO_CHECK => OP(8 downto 6), OUTPUT => compout);
  
  --This should be a std_logic_vector assignment, no comment
  assign_values_to_muxinput: for i in 0 to REGISTER_SIZE-1 generate
      opselection(0,i)<=intout(i);
      opselection(1,i)<=logiclhout(i);
      opselection(2,i)<=shiftout(i);
      opselection(3,i)<=compout(i);
  end generate;

  result_selector: ENTITY work.MUX_GENERIC
  GENERIC MAP(WIDTH => REGISTER_SIZE, HEIGHT => 4)                   
  PORT MAP(A => opselection, S => OP(4 downto 3), Y => the_result);  

  Y <= the_result;

  allatzero <= (OTHERS => '0');
  process(the_result) begin
    IF (the_result=allatzero) THEN
      FLAGS(1) <= '1';
    ELSE
      FLAGS(1) <= '0';
    END IF;
  end process;

END ARCHITECTURE;
