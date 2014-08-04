LIBRARY IEEE;
use IEEE.std_logic_1164.all;
use work.myTypes.all;

ENTITY FETCH_STAGE IS
  PORT(
    CLK: in std_logic;
    RESET: in std_logic;
    
    --Signals for code memory
    RDMEM: out std_logic;
    RDADDR: out CODE_ADDRESS;
    INST: in INSTRUCTION;

    FETCHED_INST: out INSTRUCTION;
    NOT_JMP_TAKEN: in std_logic; -- This one goes to the CU, which will decide how to compute the new address in case of wrong prediction (in this case, it will send to the ALU the fallback components of the fallback address
    -- Not needed anymore? I'm mergine BPU *and* related registers **and* checks of right/wrong prediction *into* fetch stage PC: out CODE_ADDRESS
    FLUSH_PIPELINE: out std_logic; -- As before, this is needed for the merge; could be smart

    --Get the current status of flags 
    OLD_ALU_FLAGS: in ALU_FLAGS;

  --What to replace the PC with in case of wrong prediction
    FALLBACK_ADDRESS: in CODE_ADDRESS
  );
END FETCH_STAGE;

ARCHITECTURE STRUCTURAL OF FETCH_STAGE IS
  signal the_pc:  CODE_ADDRESS_STRETCHED;
  signal the_prediction, had_wrong_prediction: std_logic;
  signal flags_tocheck, flags_tocheck_d: ALU_FLAGS;
  signal not_check_notgated, not_check, no_check_d: std_logic;
  signal tobedelayed: std_logic_vector(1 downto 0);
  signal rst_pipe_vector: std_logic_vector(0 downto 0);

  signal bubble, clk_bubblegated: std_logic;
  signal old_ir, real_ir: INSTRUCTION;
  signal old_ir_is_a_load, olddest_newsource, olddest_newsource2, bubbleforsource2, source2exists: std_logic; -- Results of comparisons of pieces of new and old IR

BEGIN

  RDMEM <= '0'; --(active low?)
  RDADDR <= the_pc & "00";
  pcmanager: entity work.PC_ACC 
  PORT MAP(
    IMMEDIATE => FALLBACK_ADDRESS;
    NEW_VALUE =>	std_logic_vector(WIDTH-1 downto 0),
		CLK => clk_bubblegated,
		RESET => RESET,
    ACC_ENABLE => '0', -- Active low
		ACC_JMP => the_prediction,
		OVERWRITE => had_wrong_prediction,
		Y => the_pc);

  my_bpu: entity work.BPU(structural_nottaken) 
  PORT MAP(
    PC => the_pc,
    CLK => CLK,
    OPCODE => opcodeof(INST),
    PRED => the_prediction,
    NO_CHECK => not_check_notgated;
  );

  ---------------------------------------------------------------------------------------------------------------------
  -- BRANCH SUPPORT/PREDICTION
  ---------------------------------------------------------------------------------------------------------------------
  --In this processor, this is what to check: note that must check ZEROFLAG=1 iff (jz && pred) || (jnz && !pred) 
  flags_tocheck(0) <= opcodeof(INST)(0) xor the_prediction;

  tobedelayed(ALU_FLAGS_SIZE) <= NO_CHECK;
  tobedelayed(ALU_FLAGS_SIZE-1 downto 0) <= FLAGS_TO_CHECK;
  delay_stage_1 : ENTITY work.REG_GENERIC
    generic map(
	  WIDTH => 2
	)
	port map(
	  D => tobedelayed,
		CK => CLK, --register can change value only if acc_en_n is '1' (acc_enable is '')
		RESET => RESET,
		Q => to_pipe_2
	);

  reg_pc : ENTITY work.REG_GENERIC
    generic map(
	  WIDTH => 2
	)
	port map(
	  D => to_pipe_2,
		CK => CLK, --register can change value only if acc_en_n is '1' (acc_enable is '')
		RESET => RESET,
		Q => delayed_tobechecked
	);
	
  no_check_d <= delayed_tobechecked(ALU_FLAGS_SIZE);
  flags_tocheck_d <= delayed_tobechecked(ALU_FLAGS_SIZE-1 downto 0);

  branch_unit: process(no_check_d, flags_tocheck_d, OLD_ALU_FLAGS)  begin
    if(OLD_ALU_FLAGS=flags_tocheck_d or no_check_d='1') then
      had_wrong_prediction <= '1';
    else
      had_wrong_prediction <= '0';
    end if;
  end process;

  flush_unit : ENTITY work.REG_GENERIC
    generic map(
	  WIDTH => 1
	)
	port map(
	  D => (0 => had_wrong_prediction, OTHERS => '0');
		CK => CLK, --register can change value only if acc_en_n is '1' (acc_enable is '')
		RESET => RESET,
		Q => rst_pipe_vector
	);

  FLUSH_PIPELINE <= rst_pipe_vector(0) or had_wrong_prediction;

  ---------------------------------------------------------------------------------------------------------------------
  -- Pipeline stall/support
  ---------------------------------------------------------------------------------------------------------------------
  oldirkeeper: ENTITY work.REG_GENERIC
  GENERIC MAP(WIDTH => 1) PORT MAP(D=>real_ir, CK => CLK, RESET => RESET, Q => old_ir);

  old_ir_is_a_load <= old_ir(IR_SIZE-1) and (not old_ir(IR_SIZE-2)) and (not old_ir(IR_SIZE-3)); -- Loads are 100xxx

  --Every instruction has at least 1 source register (with the exception of jmp). So we check it every time (TODO check if jmp? minimal change in benefits/cost)
  olddest_newsource <= '1' when old_ir(IR_SIZE-OP_CODE_SIZE-REG_ADDRESS_SIZE-1 downto IR_SIZE-OP_CODE_SIZE-REG_ADDRESS_SIZE-REG_ADDRESS_SIZE)=INST(IR_SIZE-OP_CODE_SIZE-1 downto IR_SIZE-OP_CODE_SIZE-REG_ADDRESS_SIZE) else '0';

  --Check if Dest of the load is equal to S2 of a register instruction
  olddest_newsource2 <= '1' when old_ir(IR_SIZE-OP_CODE_SIZE-REG_ADDRESS_SIZE-1 downto IR_SIZE-OP_CODE_SIZE-REG_ADDRESS_SIZE-REG_ADDRESS_SIZE)=INST(IR_SIZE-OP_CODE_SIZE-REG_ADDRESS_SIZE-1 downto IR_SIZE-OP_CODE_SIZE-REG_ADDRESS_SIZE-REG_ADDRESS_SIZE) else '0';
  bubbleforsource2 <= '1' when olddest_newsource2='1' and opcodeof(INST)=CODE_RTYPE_ADD else '0';

  bubble <= old_ir_is_a_load nand (olddest_newsource or bubbleforsource2); -- Nand because bubble is active low

  select_real_ir: ENTITY work.MUX21_GENERIC
  GENERIC MAP(WIDTH => IR_SIZE) PORT MAP(A => INST, B => ((IR_SIZE-1 downto IR_SIZE-OP_CODE_SIZE-1) => CODE_NTYPE_NOP, OTHERS => '0'), S => bubble, Y => real_ir);
  --Don't change PC if there's a bubble
  clk_bubblegated <= CLK and bubble;
  --Don't make predictions if there's a bubble
  not_check <= not_check_notgated and bubble;
  ---------------------------------------------------------------------------------------------------------------------

end ARCHITECTURE;
