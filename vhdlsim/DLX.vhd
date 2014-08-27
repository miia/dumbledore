LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE work.myTypes.ALL;
USE work.opcodes.ALL;
ENTITY DLX IS
  PORT(
  CLK: in std_logic;
  RESET: in std_logic;
  POUT: out std_logic_vector(31 downto 0) -- Connected to R30
  );
END DLX;

ARCHITECTURE structural OF DLX IS
  --SIGNALS OF THE DATAPATH
  signal RS1, RS2, RD, RS1_NCLK, RS2_NCLK, RD_FROM_IR, RD_NCLK, RDIMM, RDREG: REG_ADDRESS;
  signal IS_REGOP, IS_JAL, IS_BRANCH: std_logic; -- This signal decides which is the location of RD into the instruction register
  signal twozero: std_logic_vector(1 downto 0); -- I don't know why, but it seems VHDS can't leave OPEN part of a signal. I tried blabla(1 downto 0) => open and it complains..
  signal IMM_16, IMM_16_NCLK, IMM_16_MINUS_4: std_logic_vector(15 downto 0);
  signal RF1, RF2, EN1, S1, S2: std_logic;
  signal SELECT_REGA, SELECT_REGB: std_logic_vector(1 downto 0);
  signal ALU: ALUOP;
  signal EN2: std_logic;
  signal SIGN_EX: std_logic;
  signal RA_OUT: REGISTER_CONTENT;
  signal RM, WM, SIGN, LH, LB, EN3: std_logic;
  signal MEMDATAIN, MEMDATAOUT, MEMADDRESS: REGISTER_CONTENT;
  signal S3, WF1: std_logic; 
  signal DEBUG: string(6 downto 1); --debug thingy (could even be routed as an output of the DLX entity if we wanted; right now, you need "add wave -r *" to see it.)

  --FETCH STAGE SIGNALS
  signal RDMEM: std_logic;
  signal RDADDR: std_logic_vector(33 downto 0);
  signal INST: INSTRUCTION;
  signal FETCHED_INST_NCLK, FETCHED_INST, IR_FOR_FORWARDING: INSTRUCTION;
  signal NOT_JMP_TAKEN_NCLK, NOT_JMP_TAKEN, FLUSH_PIPELINE: std_logic;
  signal FALLBACK_ADDRESS, FALLBACK_ADDRESS_NCLK, CURRENT_PC : CODE_ADDRESS;

BEGIN
  the_datapath: ENTITY work.DLX_DATAPATH     --TODO: right now signals IMM_16 and SIGN_EX enter the datapath, but they
  PORT MAP(
  CLK => CLK, RESET => RESET,
  RS1 => RS1, RS2 => RS2, RD => RD, IMM_16 => IMM_16, PC(31 downto 2) => CURRENT_PC(29 downto 0), PC(1 downto 0) => "00", -- Fetch stage uses truncated addresses, while instruction set uses long (aligned) addresses. In order to compute fallback address as PC+1 (+imm), we compute it as imm-(not PC): remember that !pc=-pc-1 :D
  RF1 => RF1, RF2 => RF2, R30_OUT => POUT, EN1 => EN1, -- RF stage
  S1 => S1, S2 => S2, SELECT_REGA => SELECT_REGA, SELECT_REGB => SELECT_REGB, ALU => ALU, ALU_EXPORT(31 downto 2) => FALLBACK_ADDRESS_NCLK(29 downto 0),  ALU_EXPORT(1 downto 0) => twozero, -- The last 2 bits will be 0 for sure, and fetch stage uses truncated addresses
  EN2 => EN2, SIGN_EX => SIGN_EX, RA_OUT => RA_OUT, -- EX stage
  RM => RM, WM => WM, SIGN => SIGN, LH => LH, LB => LB, EN3 => EN3, MEMDATAIN => MEMDATAIN, MEMDATAOUT => MEMDATAOUT, MEMADDRESS => MEMADDRESS, S3 => S3, WF1 => WF1 -- MEM stage
  );
  FALLBACK_ADDRESS_NCLK(31 downto 30) <= "00";

  RS1_NCLK <= FETCHED_INST(25 downto 21);
  RS2_NCLK <= FETCHED_INST(20 downto 16);

  --Immediate must be transformed in -imm-4 (i.e. not(imm(15 downto 2) & "00")) when the instruction is a branch, in order to compute fallback address
  IS_BRANCH <= '1' when FETCHED_INST(31 downto 28) = "0001" else '0'; --BEZ or BNEZ
  IMM_16_MINUS_4 <= (not FETCHED_INST(15 downto 2)) & "00";
  select_right_imm16: ENTITY work.MUX21_GENERIC
  GENERIC MAP(WIDTH => 16) PORT MAP(A => IMM_16_MINUS_4, B => FETCHED_INST(15 downto 0), S => IS_BRANCH, Y => IMM_16_NCLK);

  --Destination register has two different positions depending on wether the instruction is I-TYPE (20 downto 16) or R-TYPE (15 downto 11)
  IS_REGOP <= '1' when (FETCHED_INST(31 downto 26)=OPCODE_RTYPE) else '0';
  decide_position_of_rd: ENTITY work.MUX21_GENERIC
  GENERIC MAP(WIDTH => REG_ADDRESS_SIZE) PORT MAP (A => FETCHED_INST(15 downto 11), B => FETCHED_INST(20 downto 16), S => IS_REGOP, Y => RD_FROM_IR);
  -- Destination register must be R31 if the instruction is a jump-and-link
  IS_JAL <= '1' when (opcodeof(FETCHED_INST)=OPCODE_JAL) else '0';
  decide_if_its_jal: ENTITY work.MUX21_GENERIC
  GENERIC MAP(WIDTH => REG_ADDRESS_SIZE) PORT MAP(A => "11111", B => RD_FROM_IR, S => IS_JAL, Y => RD_NCLK);

  --Puts another delay in order to align register address to CU work ( NCLK is entering the CU, while it will enter the RF on the next clock cycle)
  clk_rs1: ENTITY work.LATCH_GENERIC
    GENERIC MAP(WIDTH => 5) PORT MAP(CLK => CLK, RESET => RESET, D => RS1_NCLK, Q => RS1);
  clk_rs2: ENTITY work.LATCH_GENERIC
    GENERIC MAP(WIDTH => 5) PORT MAP(CLK => CLK, RESET => RESET, D => RS2_NCLK, Q => RS2);
  clk_imm16: ENTITY work.DELAY_BLOCK
    GENERIC MAP(WIDTH => 16, NREGS => 1) PORT MAP(CLK => CLK, RESET => RESET, D => IMM_16_NCLK, Q => IMM_16);
  clk_rd: ENTITY work.DELAY_BLOCK
    GENERIC MAP(WIDTH => 5, NREGS => 1) PORT MAP(CLK => CLK, RESET => RESET, D => RD_NCLK, Q => RD);
    clk_pc: ENTITY work.DELAY_BLOCK -- One delay is to reach the CU stage, the 2nd to reach the RF stage (register for ALU is into datapath)
  GENERIC MAP(WIDTH => 32, NREGS => 2) PORT MAP(CLK => CLK, RESET => RESET, D => RDADDR(33 downto 2), Q => CURRENT_PC);


  clk_fallback_address: ENTITY work.LATCH_GENERIC
  GENERIC MAP(WIDTH => CODE_ADDRESS_SIZE) PORT MAP(CLK => CLK, RESET => RESET, D => FALLBACK_ADDRESS_NCLK, Q => FALLBACK_ADDRESS);
  the_fetch_stage: ENTITY work.FETCH_STAGE
  PORT MAP(CLK, RESET, RDMEM, RDADDR, INST, FETCHED_INST_NCLK, NOT_JMP_TAKEN_NCLK, FLUSH_PIPELINE, RA_OUT, FALLBACK_ADDRESS);
  --Put a clock behind the instruction register in order to separate fetch stage and control unit
  clk_instruction: ENTITY work.REG_GENERIC
  GENERIC MAP(WIDTH => 32) PORT MAP(CK => CLK, RESET => RESET, D => FETCHED_INST_NCLK, Q => FETCHED_INST);

  clk_jmptaken: ENTITY work.REG_GENERIC
  GENERIC MAP(WIDTH => 1) PORT MAP(CK => CLK, RESET => RESET, D(0) => NOT_JMP_TAKEN_NCLK, Q(0) => NOT_JMP_TAKEN);
  
  the_code_memory: ENTITY work.IRAM
  PORT MAP(Rst => RESET, Addr => RDADDR(7 downto 0), Dout => INST);
      

  the_CU: ENTITY work.DLX_CU(CU_HW)
  PORT MAP(
            CLK => CLK,
            RST => RESET,
            OPCODE => FETCHED_INST(31 downto 26),
            FUNC_IN => FETCHED_INST(10 downto 0),
            PRED   => NOT_JMP_TAKEN,
            FLUSH_PIPELINE => FLUSH_PIPELINE,
            PC_EN => open,
            IR_LATCH_EN => open,
            NPC_LATCH_EN => open,
            RF1 => RF1,
            RF2 => RF2,
            EN1 => EN1,
            S1 => S1,
            S2 => S2,
            SELECT_REGA => open,
            SELECT_REGB => open,
            ALU => ALU,
            SIGN_EX => SIGN_EX,
            EN2 => EN2,
            RM => RM,
            WM => WM,
            EN3 => EN3,
            EN_LMD => open,
            LH => LH,
            LB => LB,
            SIGN_MEM => SIGN,
            S3 => S3,
            WF1 => WF1,
            DEBUG => DEBUG --debug thingy
          );
  --Forwarding unit: IR must be aligned to the instruction *entering* the ALU, so it must be delayed of 2 clock cycles w.r.t. the CU instruction
  delay_to_forwarding: ENTITY work.DELAY_BLOCK
  GENERIC MAP(WIDTH => IR_SIZE, NREGS => 2) PORT MAP(CLK => CLK, RESET => RESET, D => FETCHED_INST, Q => IR_FOR_FORWARDING);
  forward_blocK: ENTITY work.FORWARDER
  PORT MAP(CLK => CLK, RESET => RESET, IR => IR_FOR_FORWARDING, SELECT_RIGHTA => SELECT_REGA, SELECT_RIGHTB => SELECT_REGB);
END ARCHITECTURE;



