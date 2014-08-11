LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE work.myTypes.ALL;
ENTITY DLX IS
  PORT(
  CLK: in std_logic;
  RESET: in std_logic;
  POUT: out std_logic_vector(31 downto 0) -- Connected to R30
  );
END DLX;

ARCHITECTURE structural OF DLX IS
  --SIGNALS OF THE DATAPATH
  signal RS1, RS2, RD: REG_ADDRESS;
  signal RF1, RF2, EN1, S1, S2: std_logic;
  signal SELECT_REGA, SELECT_REGB: std_logic_vector(1 downto 0);
  signal ALU: ALUOP;
  signal EN2: std_logic;
  signal ALU_FLAGS_OUT: ALU_FLAGS;
  signal RM, WM, SIGN, LH, LB, EN3: std_logic;
  signal MEMDATAIN, MEMDATAOUT, MEMADDRESS: REGISTER_CONTENT;
  signal S3, WF1: std_logic; 

  --FETCH STAGE SIGNALS
  signal RDMEM: std_logic;
  signal RDADDR: std_logic_vector(33 downto 0);
  signal INST: INSTRUCTION;
  signal FETCHED_INST: INSTRUCTION;
  signal NOT_JMP_TAKEN, FLUSH_PIPELINE: std_logic;
  signal OLD_ALU_FLAGS: ALU_FLAGS; -- TODO replace with register content (branch condition is on register contents)
  signal FALLBACK_ADDRESS: CODE_ADDRESS;

BEGIN
  the_datapath: ENTITY work.DLX_DATAPATH 
  PORT MAP(
  CLK => CLK, RESET => RESET,
  RS1 => RS1, RS2 => RS2, RD => RD, RF1 => RF1, RF2 => RF2, R30_OUT => POUT, EN1 => EN1, -- RF stage
  S1 => S1, S2 => S2, SELECT_REGA => SELECT_REGA, SELECT_REGB => SELECT_REGB, ALU => ALU, EN2 => EN2, ALU_FLAGS_OUT => ALU_FLAGS_OUT, -- EX stage
  RM => RM, WM => WM, SIGN => SIGN, LH => LH, LB => LB, EN3 => EN3, MEMDATAIN => MEMDATAIN, MEMDATAOUT => MEMDATAOUT, MEMADDRESS => MEMADDRESS, S3 => S3, WF1 => WF1 -- MEM stage
  );

  the_fetch_stage: ENTITY work.FETCH_STAGE
  PORT MAP(CLK, RESET, RDMEM, RDADDR, INST, FETCHED_INST, NOT_JMP_TAKEN, FLUSH_PIPELINE, OLD_ALU_FLAGS, FALLBACK_ADDRESS);
  
  the_code_memory: ENTITY work.IRAM
  PORT MAP(Rst => RESET, Addr => RDADDR(5 downto 0), Dout => INST);

  the_CU: ENTITY work.DLX_CU
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
            EN2 => EN2,
            RM => RM,
            WM => WM,
            EN3 => EN3,
            EN_LMD => open,
            LH => LH,
            LB => LB,
            SIGN => SIGN,
            S3 => S3,
            WF1 => WF1
          );

END ARCHITECTURE;



