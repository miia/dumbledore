ENTITY DLX_DATAPATH IS
  PORT(

      )
  END DLX_DATAPATH;
 
ARCHITECTURE dlx_simple OF DLX_DATAPATH IS

  -- SIGNALS FOR THE CONTROL UNIT
  signal CLK                : in  std_logic;
  signal RST                : in  std_logic;
  signal OPCODE             : in CODE; --this input will be connected to the 6 Opcode bits of the IR
  signal FUNC_IN              : in FUNC; --this input will be conected to the 11 Function bits of the IR

  signal RF1      : out std_logic;  -- Register A Latch Enable
  signal RF2      : out std_logic;  -- Register B Latch Enable
  signal EN1      : out std_logic;  -- Register file / Immediate Register Enable

  signal -- EX Control Signals
  signal S1           : out std_logic;  -- MUX-A Sel
  signal S2           : out std_logic;  -- MUX-B Sel
  signal ALU         : out ALUOP; -- ALU Operation Code
  signal EN2      : out std_logic;  -- ALU Output Register Enable
  signal 
  signal -- MEM/WB Control Signals
  signal RM            : out std_logic;  -- Data RAM Read Enable
  signal WM            : out std_logic;  -- Data RAM Write Enable
  signal EN3            : out std_logic;  -- Data RAM Enable

  signal S3         : out std_logic;  -- Write Back MUX Sel
  signal WF1              : out std_logic -- Register File Write Enable

  signal pipe1A_out: REGISTER_CONTENT;
  signal pipe1B_out: REGISTER_CONTENT;
  signal pipe1in2_out: REGISTER_CONTENT;-- We put immediate in the B side of the ALU so that we can make SUBI
  signal ALU_A, ALU_B: REGISTER_CONTENT;-- Data input for ALU
  
BEGIN
    
  -- FETCH stage
  fetchs: ENTITY work.fetch_stage

  PORT MAP();

  --DECODE/DATAREAD STAGE
  regfile: ENTITY work.REGISTER_FILE
  GENERIC MAP(NREGS => 2**(REG_ADDRESS_SIZE), REG_WIDTH => REGISTER_SIZE)
  PORT MAP(
  CLK => CLK,
  RESET => RESET,
  ENABLE => EN1,
  RD1 => RF1,
  RD2 => RF2,
  WR => WF1,
  ADD_WR => pipe2rd2_out,
  ADD_RD1 => RS1,
  ADD_RD2 => RS2,
  DATAIN => writeback_data,
  OUT1 => pipe1a_in,
  OUT2 => pipe1b_in
);

  pipe1a: ENTITY work.REG_GENERIC
  GENERIC MAP(WIDTH => REGISTER_SIZE) PORT MAP (D => pipe1a_in, CLK, RESET, pipe1a_out);

  pipe1b: ENTITY work.REG_GENERIC
  GENERIC MAP(WIDTH => REGISTER_SIZE) PORT MAP (D => pipe1b_in, CK => CLK, RESET => RESET, Q => pipe1b_out);

  pipe1in2: ENTITY work.REG_GENERIC
  GENERIC MAP(WIDTH => REGISTER_SIZE) PORT MAP(D => pipe1in2_in, CK => CLK, RESET => RESET, Q => pipe1in2_out);

  pipe1rd1: ENTITY work.REG_GENERIC GENERIC MAP(WIDTH => REG_ADDRESS_SIZE) PORT MAP(D => pipe1rd1_in CK => CLK, RESET => RESET, Q => pipe1rd1_out);


  --EXECUTE STAGE
  select_immediate: ENTITY work.MUX21_GENERIC
  GENERIC MAP(WIDTH => REGISTER_SIZE) PORT MAP(A=>pipe1B_out, B=> pipe1in2_out, S=>S1, Y => ALU_B);

  myAlu: ENTITY work.DLX_ALU
  GENERIC MAP(A => pipe1A_out, B=> ALU_B, OP => alu_operation, Y => ALU_OUT, FLAGS => ALU_FLAGS_OUT); 

  --EXEC PIPES
  --Note/TODO: it should be smart to attach alu B operand to memory data input so that we can store immediates
  pipe2aluout: ENTITY work.REG_GENERIC
  GENERIC MAP(WIDTH => REGISTER_SIZE) PORT MAP(D => ALU_OUT, CK => CLK, RESET => RESET, Q => pipe2aluout_out);

  pipe2me: ENTITY work.REG_GENERIC
  GENERIC MAP(WIDTH => REGISTER_SIZE) PORT MAP(D => pipe1b_out, CK => CLK, RESET => RESET, Q => pipe2me_out);

  pipe2rd2: ENTITY work.REG_GENERIC
  GENERIC MAP(WIDTH => REG_ADDRESS_SIZE) PORT MAP(D => pipe1rd1_out, CK => CLK, RESET => RESET, Q => pipe2rd2_out);

  --MEM/WB STAGE
  memory: ENTITY work.DATA_MEMORY
  PORT MAP(READ => RM, WRITE => WM, ENABLE => EN3, ADDRESS => pipe2aluout_out, DATA => pipe2me_out, Y => memory_out);

  mem_alu_selector: ENTITY work.MUX21
  GENERIC MAP(WIDTH => REGISTER_SIZE, A=>pipe2aluout_out, B=> memory_out, S=> S3, Y=> writeback_data);

  --MEM/WB PIPES - What is "OUT" needed to?
  pipe3out: ENTITY work.REG_GENERIC
  GENERIC MAP(WIDTH => REGISTER_SIZE) PORT MAP(D => writeback_data, CK => CLK, RESET => RESET, Q => pipe3out_out);


  execs: ENTITY work.execute_stage
  PORT MAP();

  wb: ENTITY work.wb_stage
  PORT MAP();

END ARCHITECTURE;

