library IEEE;
use IEEE.std_logic_1164.all;
use work.myTypes.all;
use work.mux_generic_input.all;

ENTITY DLX_DATAPATH IS
  PORT(

  -- SIGNALS FOR THE CONTROL UNIT
 CLK                : in  std_logic;
 RESET                : in  std_logic;

 RS1      : in REG_ADDRESS; --Source registers
 RS2      : in REG_ADDRESS;
 RD       : in REG_ADDRESS; -- Destination registers
 IMM_16   : in std_logic_vector(15 downto 0);  --16-bit immediate value from IR - needs to be extended to 32 bits
 PC       : in std_logic_vector(31 downto 0); -- This will be the other immediate value - INP1
 
 RF1      : in std_logic;  -- Register A Latch Enable
 RF2      : in std_logic;  -- Register B Latch Enable
 R30_OUT  : out REGISTER_CONTENT; -- Output from register R30
 ALU_EXPORT: out REGISTER_CONTENT; -- Output from the ALU -- where to get the fallback address
 EN1      : in std_logic;  -- Register file / Immediate Register Enable


 -- EX Control Signals
 S1           : in std_logic;  -- MUX-A Sel
 S2           : in std_logic;  -- MUX-B Sel
 SELECT_REGA : in std_logic_vector(1 downto 0);
 SELECT_REGB : in std_logic_vector(1 downto 0);
 ALU         : in ALUOP; -- ALU Operation Code
 SIGN_EX     : in std_logic;  --signed/unsigned extension of immediate operand from IR
 EN2      : in std_logic;  -- ALU Output Register Enable
 RA_OUT: out REGISTER_CONTENT;
 
 -- MEM/WB Control Signals
 RM            : in std_logic;  -- Data RAM Read Enable
 WM            : in std_logic;  -- Data RAM Write Enable
 SIGN           : in std_logic; -- Data read unsigned/signed
 LH             : in std_logic; -- Read/write half word
 LB             : in std_logic; -- Read/write single byte (must be LH==LB==1 to read a byte)
 EN3            : in std_logic;  -- Data RAM Enable
 
 --Outputs for memory
 MEMDATAIN      :  out REGISTER_CONTENT;
 MEMDATAOUT     :  in REGISTER_CONTENT;
 MEMADDRESS     :  out REGISTER_CONTENT;

 S3         : in std_logic;  -- Write Back MUX Sel
 WF1              : in std_logic -- Register File Write Enable
      );
  END DLX_DATAPATH;
 
ARCHITECTURE dlx_simple OF DLX_DATAPATH IS

  signal pipe1a_in, pipe1a_out: REGISTER_CONTENT;
  signal pipe1b_in, pipe1b_out: REGISTER_CONTENT;
  signal pipe1in2_in, pipe1in2_out : std_logic_vector(REGISTER_SIZE/2-1 downto 0); -- this register holds the Immediate value coming fromthe IR, BEFORE its extension to 32 bits (which takes place in the EX stage).
  signal pipe1in1_in, pipe1in1_out, memory_out, pipe3out_out: REGISTER_CONTENT;-- We put immediate in the B side of the ALU so that we can make SUBI
  signal pipe1rd1_out, pipe2rd2_out, pipe3rd3_out: REG_ADDRESS;
  signal ALU_A, ALU_B, ALU_OUT, pipe2aluout_out, pipe2me_out, writeback_data: REGISTER_CONTENT;-- Data input for ALU
  signal regO_out, regBa_out, rightA_out, rightB_out: REGISTER_CONTENT;-- Data input for ALU
  signal input_for_right_a, input_for_right_b: mux_generic_input(3 downto 0, REGISTER_SIZE-1 downto 0);
  signal imm_extender_out, minusfour: REGISTER_CONTENT;
  
  signal pc_value : std_logic_vector(31 downto 0); -- carries current PC value out of fetch stage and into the ALU. (32 = width of Accumulator in fetch_stage)
  
  
BEGIN
    
  --DECODE/DATAREAD STAGE
  regfile: ENTITY work.REGISTER_FILE
  GENERIC MAP(NREGS => 2**(REG_ADDRESS_SIZE), REG_WIDTH => REGISTER_SIZE, TO_SEND => 30)
  PORT MAP(
  CLK => CLK,
  RESET => RESET,
  ENABLE => EN1,
  RD1 => RF1,
  RD2 => RF2,
  WR => WF1,
  ADD_WR => pipe3rd3_out,
  ADD_RD1 => RS1,
  ADD_RD2 => RS2,
  DATAIN => pipe3out_out,
  OUT1 => pipe1a_in,
  OUT2 => pipe1b_in,
  REG_FIXED_OUT => R30_OUT
);

  pipe1a: ENTITY work.REG_GENERIC
  GENERIC MAP(WIDTH => REGISTER_SIZE) PORT MAP (D => pipe1a_in, CK => CLK, RESET => RESET, Q => pipe1a_out);

  pipe1b: ENTITY work.REG_GENERIC
  GENERIC MAP(WIDTH => REGISTER_SIZE) PORT MAP (D => pipe1b_in, CK => CLK, RESET => RESET, Q => pipe1b_out);

  pipe1in1_in <= PC;
  pipe1in1: ENTITY work.REG_GENERIC
  GENERIC MAP(WIDTH => REGISTER_SIZE) PORT MAP(D => pipe1in1_in, CK => CLK, RESET => RESET, Q => pipe1in1_out);

  pipe1in2: ENTITY work.REG_GENERIC
  GENERIC MAP(WIDTH => REGISTER_SIZE/2) PORT MAP(D => IMM_16, CK => CLK, RESET => RESET, Q => pipe1in2_out); --NOTE: this register holds the Immediate value coming from the IR, BEFORE its extension to 32 bits. extension is done in the EX stage, just before operations involving the value.

  pipe1rd1: ENTITY work.REG_GENERIC GENERIC MAP(WIDTH => REG_ADDRESS_SIZE) PORT MAP(D => RD, CK => CLK, RESET => RESET, Q => pipe1rd1_out);


  --EXECUTE STAGE

  ----------------------------------------------------------------------------------------------------------------------------

  --extend Immediate value to 32 bits before feeding it into the ALU (through a mux)
  immediate_extender: ENTITY work.IMM_EXTENDER
  PORT MAP(INPUT => pipe1in2_out, SIGN => SIGN_EX, OUTPUT => imm_extender_out); --NOTE: signed/unsigned extension driven by the SAME bit driving signed/unsigned operations in the ALU

  --Select the right value for read registers and overwrite register which still have not been writeback'd (data forwarding)

  --This should be a std_logic_vector assignment, no comment
  --Selection is driven from outside: 0 is "0000", 1 is real register, 2 is input from regO, 3 is regBa
  minusfour<=(REGISTER_SIZE-1 downto 2 => '1', 1 downto 0 => '0'); -- -4: to be used for PC overwrite
  assign_values: for i in 0 to REGISTER_SIZE-1 generate

    input_for_right_a(0,i)<='0';
    input_for_right_a(1,i)<=pipe1a_out(i); --coming from RF output (will be regA operand for ALU)
    input_for_right_a(2,i)<=regO_out(i);
    input_for_right_a(3,i)<=regBa_out(i);

    input_for_right_b(0,i) <= minusfour(i);
    input_for_right_b(1,i)<=pipe1b_out(i); --coming from RF output (will be regB operand for ALU)
    input_for_right_b(2,i)<=regO_out(i);
    input_for_right_b(3,i)<=regBa_out(i);
  end generate;

  which_is_right_a: ENTITY work.MUX_GENERIC
  GENERIC MAP(WIDTH => REGISTER_SIZE, HEIGHT => 4) PORT MAP(A => input_for_right_a, S => SELECT_REGA, Y => rightA_out);

  which_is_right_b: ENTITY work.MUX_GENERIC
  GENERIC MAP(WIDTH => REGISTER_SIZE, HEIGHT => 4) PORT MAP(A => input_for_right_b, S => SELECT_REGB, Y => rightB_out);
  -- This signal will be used by the fetch stage to check for branches
  RA_OUT <= rightA_out;
  ----------------------------------------------------------------------------------------------------------------------------


  select_immediate: ENTITY work.MUX21_GENERIC
  GENERIC MAP(WIDTH => REGISTER_SIZE) PORT MAP(B=>rightB_out, A=> imm_extender_out, S=>S2, Y => ALU_B);

  select_PC: ENTITY work.MUX21_GENERIC
  GENERIC MAP(WIDTH => REGISTER_SIZE) PORT MAP(A=>pipe1in1_out, B=> rightA_out, S=>S1, Y => ALU_A);

  --ALU OPCODES
  --5 bits
  --1st bit is Immediate/register switch (used to select NOT or LH - 1=LH, 0=NOT)
  --2 bits=unit
  --00=arith
  --01=logic
  --10/11=shifter
  --
  --Arithmetics
  --00xx
  --00=ADD
  --01=SUB (bit 0 goes to sign selector)
  --
  --10=MUL (unsigned)
  --11=MUL (signed)
  --
  --Logic
  --01xx
  --
  --00=OR
  --01=AND
  --10=XOR
  --(11=NOT?)
  --
  --Shifter
  --10xx/11xx=1xxx
  --
  --Last bit is L/R
  --Middle bit is Shift/Rotate
  --MSB is Logic/Arith - When not used, it can be used for sign extension of the operand - EDIT: Note that this is not needed as the operand is only 5 bits
  --i.e.
  --101=Logic rotate Left
  --010=Arith shift right
  --and so on..
  myAlu: ENTITY work.DLX_ALU
  PORT MAP(A => ALU_A, B=> ALU_B, OP => ALU, Y => ALU_OUT, Y_extended => OPEN); 

  --EXEC PIPES
  --Note/TODO: it should be smart to attach alu B operand to memory data input so that we can store immediates

  pipe2aluout: ENTITY work.REG_GENERIC
  GENERIC MAP(WIDTH => REGISTER_SIZE) PORT MAP(D => ALU_OUT, CK => CLK, RESET => RESET, Q => pipe2aluout_out);

  --This registers store ALU OUT from the previous operations, and are used for data forwarding through the pipeline.
  -- Note that pipe2aluout is doubled here to regO; this is because pipe2aluout will be changed to a LATCH instead of a register, but a latch CAN'T be used for this purpose as it could introduce an infinite loop if regO is read (and written) from the ALU in transparent mode.
  regO: ENTITY work.REG_GENERIC
  GENERIC MAP(WIDTH => REGISTER_SIZE) PORT MAP(D => ALU_OUT, CK => CLK, RESET => RESET, Q => regO_out);

  regBa: ENTITY work.REG_GENERIC
  GENERIC MAP(WIDTH => REGISTER_SIZE) PORT MAP(D => writeback_data, CK => CLK, RESET => RESET, Q => regBa_out);

  pipe2me: ENTITY work.REG_GENERIC
  GENERIC MAP(WIDTH => REGISTER_SIZE) PORT MAP(D => rightB_out, CK => CLK, RESET => RESET, Q => pipe2me_out);

  pipe2rd2: ENTITY work.REG_GENERIC
  GENERIC MAP(WIDTH => REG_ADDRESS_SIZE) PORT MAP(D => pipe1rd1_out, CK => CLK, RESET => RESET, Q => pipe2rd2_out);

  MEMADDRESS <= pipe2aluout_out;
  MEMDATAIN <= pipe2me_out;
  memory_out <= MEMDATAOUT;

  mem_alu_selector: ENTITY work.MUX21_GENERIC
  GENERIC MAP(WIDTH => REGISTER_SIZE) PORT MAP(A=>pipe2aluout_out, B=> memory_out, S=> S3, Y=> writeback_data);

  --MEM/WB PIPES - What is "OUT" needed to?
  --MEM/WB STAGE

  -- ADDR is the address of the data to read/write; if it is not aligned to the size of the data to read/write, it will be truncated.
  -- E.g. if addr=xxxxx0111 and size=word, address will be truncated to xxxxx0100.
  -- LH/LB control the size of the data to read/write:
  -- LH=1, LB=1 => Byte
  -- LH=1, LB=0 => Half word
  -- LH=0, LB=0 => word
  memory: ENTITY work.MEMORY_STAGE
  PORT MAP(CLK => CLK, RESET => RESET, ADDR => pipe2aluout_out, RD_MEM => RM, WR => WM, SIGN => SIGN, LH => LH, LB => LB, DATA_IN => pipe2me_out, DATA_OUT => memory_out);
  pipe3out: ENTITY work.LATCH_GENERIC
  GENERIC MAP(WIDTH => REGISTER_SIZE) PORT MAP(D => writeback_data, CLK => CLK, RESET => RESET, Q => pipe3out_out);
  pipe3rd3: ENTITY work.LATCH_GENERIC
  GENERIC MAP(WIDTH => REG_ADDRESS_SIZE) PORT MAP(D => pipe2rd2_out, CLK => CLK, RESET => RESET, Q => pipe3rd3_out);

  ALU_EXPORT <= ALU_OUT;

END ARCHITECTURE;

