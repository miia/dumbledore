LIBRARY IEEE;
use IEEE.std_logic_1164.all;
use work.myTypes.all;

ENTITY FETCH_STAGE IS
  PORT(
    CLK: in std_logic;
    RESET: in std_logic;
    
    --Signals for code memory
    RDMEM: out std_logic;
    RDADDR: out std_logic_vector(33 downto 0);
    INST: in INSTRUCTION;

    FETCHED_INST: out INSTRUCTION;
    NOT_JMP_TAKEN: out std_logic; -- This one goes to the CU, which will decide how to compute the new address in case of wrong prediction (in this case, it will send to the ALU the fallback components of the fallback address
    -- Not needed anymore? I'm mergine BPU *and* related registers **and* checks of right/wrong prediction *into* fetch stage PC: out CODE_ADDRESS
    FLUSH_PIPELINE: out std_logic; -- As before, this is needed for the merge; could be smart

    CHECK_REGISTER: in REGISTER_CONTENT; -- Here it will come the content of the register to be checked for the jump

  --What to replace the PC with in case of wrong prediction
    FALLBACK_ADDRESS: in CODE_ADDRESS
  );
END FETCH_STAGE;

ARCHITECTURE STRUCTURAL OF FETCH_STAGE IS
  signal the_pc:  CODE_ADDRESS;
  signal the_prediction, had_wrong_prediction, had_wrong_prediction_nclk: std_logic;
  signal flags_tocheck, flags_tocheck_d: std_logic;
  signal not_check_notgated, not_check, no_check_d: std_logic;
  signal set_wrong_force_notgated, set_wrong_force, set_wrong_force_d: std_logic;
  signal tobedelayed, to_pipe_2, delayed_tobechecked: std_logic_vector(2 downto 0);
  signal rst_pipe: std_logic_vector(1 downto 0);

  signal bubble, nbubble, clk_bubblegated: std_logic;
  signal old_ir, real_ir: INSTRUCTION;
  signal old_ir_is_a_load, olddest_newsource, olddest_newsource2, bubbleforsource2, source2exists: std_logic; -- Results of comparisons of pieces of new and old IR
  signal immediate_extended: std_logic_vector(33 downto 0);
  --Get the current status of result 
  signal reg_is_zero: std_logic;
  signal allatzero: REGISTER_CONTENT;
BEGIN

  RDMEM <= '0'; --(active low?)
  RDADDR <= the_pc & "00";
  immediate_extended(15 downto 0)  <= imm16of(INST);
  
  extend_immediate: for i in 16 to 25 generate
   immediate_extended(i) <= INST(i) WHEN INST(2)='0' ELSE imm16of(INST)(15);
  end generate;
  extend_immediate_2ndpart_killme: for i in 26 to CODE_ADDRESS_SIZE+1 generate -- Extends up to 2 bit more than the size of immediate, as it will be always a multiple of 4: the last 2 bits of immediate will be truncated entering the accumulator
   immediate_extended(i) <= immediate_extended(25);
  end generate;
  
  nbubble <= (not bubble) and (not had_wrong_prediction);  -- This signal controls the *active low* enable for the accumulator: it must not be enabled when there is a bubble (!bubble) and there is no wrong prediction (in case of a wrong prediction overwrite is forced (even if there was a bubble, because it was a "wrong predicted" bubble (oh god so many parenthesis (I should have written this in LISP))))
  pcmanager: entity work.PC_ACC 
  GENERIC MAP(
      WIDTH => 32
  )
  PORT MAP(
    IMMEDIATE => immediate_extended(CODE_ADDRESS_SIZE+1 downto 2),
    NEW_VALUE =>	FALLBACK_ADDRESS,
		CLK => clk,
		RESET => RESET,
    ACC_ENABLE => nbubble, -- Active low - Don't change PC if there's a bubble
		ACC_JMP => the_prediction,
		OVERWRITE => had_wrong_prediction,
		Y => the_pc);

  my_bpu: entity work.BPU(structural_nottaken) 
  PORT MAP(
    PC => the_pc,
    CLK => CLK,
    OPCODE => opcodeof(INST),
    PRED => the_prediction,
    NO_CHECK => not_check_notgated,
    FORCE_WRONG => set_wrong_force_notgated
  );

  ---------------------------------------------------------------------------------------------------------------------
  -- BRANCH SUPPORT/PREDICTION
  ---------------------------------------------------------------------------------------------------------------------
  NOT_JMP_TAKEN <= not the_prediction;
  --In this processor, this is what to check: note that must check ZEROFLAG=1 iff (jz && pred) || (jnz && !pred) 
  flags_tocheck <= opcodeof(INST)(0) xor the_prediction;

  tobedelayed(2) <= set_wrong_force;
  tobedelayed(1) <= not not_check; --UGLY fix: temporarly transform not check to active-low, so that if register is resetted, first instruction will not be checked.
  tobedelayed(0) <= flags_tocheck;
  delay_predictions : ENTITY work.DELAY_BLOCK
    generic map(
	  WIDTH => 3, NREGS => 3
	)
	port map(
	  D => tobedelayed,
		CLK => CLK, --register can change value only if acc_en_n is '1' (acc_enable is '')
		RESET => RESET,
		Q => delayed_tobechecked
	);
  set_wrong_force_d <= delayed_tobechecked(2);
  no_check_d <= not delayed_tobechecked(1); -- See above
  flags_tocheck_d <= delayed_tobechecked(0);

  -- Generates zero flag to be checked by the branch unit
  allatzero <= (OTHERS => '0');
  check_if_reg_is_zero: process(CHECK_REGISTER) begin
    if(CHECK_REGISTER=allatzero) then
      reg_is_zero <= '1';
    else
      reg_is_zero <= '0';
    end if;
  end process;

  -- Checks the content of the register (set into reg_is_zero) with the DELAYED zero flag generated by the BPU
  branch_unit: process(no_check_d, flags_tocheck_d, reg_is_zero)  begin
    if((reg_is_zero=flags_tocheck_d or no_check_d='1') and (set_wrong_force_d='0')) then -- Active high signals
      had_wrong_prediction_nclk <= '0';
    else
      had_wrong_prediction_nclk <= '1';
    end if;
  end process;
  clock_overwrite: ENTITY work.LATCH_GENERIC
  GENERIC MAP(WIDTH => 1) PORT MAP(CLK => CLK, RESET => RESET, D(0) => had_wrong_prediction_nclk, Q(0) => had_wrong_prediction);

  --Keeps flushing for 3 clock cycles. Not that had_wrong_prediction is inverted here so that a reset will cause a pipeline flush.
  flush_unit1 : ENTITY work.REG_GENERIC
    generic map(
	  WIDTH => 1
	)
	port map(
	  D(0) => not had_wrong_prediction,
		CK => CLK,
		RESET => RESET,
		Q(0) => rst_pipe(0)
	);
  flush_unit2 : ENTITY work.REG_GENERIC
    generic map(
	  WIDTH => 1
	)
	port map(
	  D(0) => rst_pipe(0),
		CK => CLK,
		RESET => RESET,
		Q(0) => rst_pipe(1)
	);

  FLUSH_PIPELINE <= (not rst_pipe(1)) or (not rst_pipe(0)) or had_wrong_prediction; -- Both are active high and produce an active high

  ---------------------------------------------------------------------------------------------------------------------
  -- Pipeline stall/support
  ---------------------------------------------------------------------------------------------------------------------
  oldirkeeper: ENTITY work.REG_GENERIC
  GENERIC MAP(WIDTH => IR_SIZE) PORT MAP(D=>real_ir, CK => CLK, RESET => RESET, Q => old_ir);

  old_ir_is_a_load <= old_ir(IR_SIZE-1) and (not old_ir(IR_SIZE-2)) and (not old_ir(IR_SIZE-3)); -- Loads are 100xxx

  --Every instruction has at least 1 source register (with the exception of jmp). So we check it every time (TODO check if jmp? minimal change in benefits/cost)
  olddest_newsource <= '1' when old_ir(IR_SIZE-OP_CODE_SIZE-REG_ADDRESS_SIZE-1 downto IR_SIZE-OP_CODE_SIZE-REG_ADDRESS_SIZE-REG_ADDRESS_SIZE)=INST(IR_SIZE-OP_CODE_SIZE-1 downto IR_SIZE-OP_CODE_SIZE-REG_ADDRESS_SIZE) else '0';

  --Check if Dest of the load is equal to S2 of a register instruction
  olddest_newsource2 <= '1' when old_ir(IR_SIZE-OP_CODE_SIZE-REG_ADDRESS_SIZE-1 downto IR_SIZE-OP_CODE_SIZE-REG_ADDRESS_SIZE-REG_ADDRESS_SIZE)=INST(IR_SIZE-OP_CODE_SIZE-REG_ADDRESS_SIZE-1 downto IR_SIZE-OP_CODE_SIZE-REG_ADDRESS_SIZE-REG_ADDRESS_SIZE) else '0';
  bubbleforsource2 <= '1' when olddest_newsource2='1' and opcodeof(INST)=CODE_RTYPE_ADD else '0';

  bubble <= old_ir_is_a_load nand (olddest_newsource or bubbleforsource2); -- Nand because bubble is active low

  select_real_ir: ENTITY work.MUX21_GENERIC
  GENERIC MAP(WIDTH => IR_SIZE) PORT MAP(A => INST, B => A_NOP, S => bubble, Y => real_ir);
  FETCHED_INST <= real_ir;

  --Don't make predictions if there's a bubble
  not_check <= not_check_notgated or (not bubble);
  --Never force wrong if there is a bubble
  set_wrong_force <= set_wrong_force_notgated and (not bubble);
  ---------------------------------------------------------------------------------------------------------------------

end ARCHITECTURE;
