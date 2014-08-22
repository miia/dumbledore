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
  signal RS1, RS2, RD, RDIMM, RDREG: REG_ADDRESS;
  signal IS_REGOP: std_logic; -- This signal decides which is the location of RD into the instruction register
  signal IMM_16: std_logic_vector(15 downto 0);
  signal RF1, RF2, EN1, S1, S2: std_logic;
  signal SELECT_REGA, SELECT_REGB: std_logic_vector(1 downto 0);
  signal ALU: ALUOP;
  signal EN2: std_logic;
  signal SIGN_EX: std_logic;
  signal RA_OUT: REGISTER_CONTENT;
  signal RM, WM, SIGN, LH, LB, EN3: std_logic;
  signal MEMDATAIN, MEMDATAOUT, MEMADDRESS: REGISTER_CONTENT;
  signal S3, WF1: std_logic; 

  --FETCH STAGE SIGNALS
  signal RDMEM: std_logic;
  signal RDADDR: std_logic_vector(33 downto 0);
  signal INST: INSTRUCTION;
  signal FETCHED_INST_NCLK, FETCHED_INST: INSTRUCTION;
  signal NOT_JMP_TAKEN_NCLK, NOT_JMP_TAKEN, FLUSH_PIPELINE: std_logic;
  signal FALLBACK_ADDRESS: CODE_ADDRESS;

BEGIN
  the_datapath: ENTITY work.DLX_DATAPATH     --TODO: right now signals IMM_16 and SIGN_EX enter the datapath, but they
  PORT MAP(
  CLK => CLK, RESET => RESET,
  RS1 => RS1, RS2 => RS2, RD => RD, IMM_16 => IMM_16, RF1 => RF1, RF2 => RF2, R30_OUT => POUT, EN1 => EN1, -- RF stage
  S1 => S1, S2 => S2, SELECT_REGA => SELECT_REGA, SELECT_REGB => SELECT_REGB, ALU => ALU, EN2 => EN2, SIGN_EX => SIGN_EX, RA_OUT => RA_OUT, -- EX stage
  RM => RM, WM => WM, SIGN => SIGN, LH => LH, LB => LB, EN3 => EN3, MEMDATAIN => MEMDATAIN, MEMDATAOUT => MEMDATAOUT, MEMADDRESS => MEMADDRESS, S3 => S3, WF1 => WF1 -- MEM stage
  );

  RS1 <= FETCHED_INST(25 downto 21);
  RS2 <= FETCHED_INST(20 downto 16);
  IMM_16 <= FETCHED_INST(15 downto 0);

  --Destination register has two different positions depending on wether the instruction is I-TYPE (20 downto 16) or R-TYPE (15 downto 11)
  IS_REGOP <= '1' when (FETCHED_INST(31 downto 26)=OPCODE_RTYPE) else '0';
  decide_position_of_rd: ENTITY work.MUX21_GENERIC
  GENERIC MAP(WIDTH => REG_ADDRESS_SIZE) PORT MAP (A => FETCHED_INST(15 downto 11), B => FETCHED_INST(20 downto 16), S => IS_REGOP, Y => RD);

  the_fetch_stage: ENTITY work.FETCH_STAGE
  PORT MAP(CLK, RESET, RDMEM, RDADDR, INST, FETCHED_INST_NCLK, NOT_JMP_TAKEN_NCLK, FLUSH_PIPELINE, RA_OUT, FALLBACK_ADDRESS);
  --Put a clock behind the instruction register in order to separate fetch stage and control unit
  clk_instruction: ENTITY work.REG_GENERIC
  GENERIC MAP(WIDTH => 32) PORT MAP(CK => CLK, RESET => RESET, D => FETCHED_INST_NCLK, Q => FETCHED_INST);

  clk_jmptaken: ENTITY work.REG_GENERIC
  GENERIC MAP(WIDTH => 1) PORT MAP(CK => CLK, RESET => RESET, D(0) => NOT_JMP_TAKEN_NCLK, Q(0) => NOT_JMP_TAKEN);
  
  the_code_memory: ENTITY work.IRAM
  PORT MAP(Rst => RESET, Addr => RDADDR(5 downto 0), Dout => INST);
      

  the_CU: ENTITY work.DLX_CU(CU_HW)
  PORT MAP(
            CLK => CLK,
            RST => RESET,
            OPCODE => FETCHED_INST(31 downto 26),
            FUNC_IN => FETCHED_INST(10 downto 0),
            PC_EN => open,
            IR_LATCH_EN => open,
            NPC_LATCH_EN => open,
            RF1 => RF1,
            RF2 => RF2,
            EN1 => EN1,
            S1 => S1,
            S2 => S2,
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
            WF1 => WF1
          );

END ARCHITECTURE;



