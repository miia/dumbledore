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
 
 RF1      : in std_logic;  -- Register A Latch Enable
 RF2      : in std_logic;  -- Register B Latch Enable
 R30_OUT  : out REGISTER_CONTENT; -- Output from register R30
 EN1      : in std_logic;  -- Register file / Immediate Register Enable

 -- EX Control Signals
 S1           : in std_logic;  -- MUX-A Sel
 S2           : in std_logic;  -- MUX-B Sel
 SELECT_REGA : in std_logic_vector(1 downto 0);
 SELECT_REGB : in std_logic_vector(1 downto 0);
 ALU         : in ALUOP; -- ALU Operation Code
 EN2      : in std_logic;  -- ALU Output Register Enable
 ALU_FLAGS_OUT: out ALU_FLAGS;
 
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
  signal pipe1in1_in, pipe1in1_out, pipe1in2_in, pipe1in2_out, memory_out, pipe3out_out: REGISTER_CONTENT;-- We put immediate in the B side of the ALU so that we can make SUBI
  signal pipe1rd1_out, pipe2rd2_out: REG_ADDRESS;
  signal ALU_A, ALU_B, ALU_OUT, pipe2aluout_out, pipe2me_out, writeback_data: REGISTER_CONTENT;-- Data input for ALU
  signal regO_out, regBa_out, rightA_out, rightB_out: REGISTER_CONTENT;-- Data input for ALU
  signal input_for_right_a, input_for_right_b: mux_generic_input(3 downto 0, REGISTER_SIZE-1 downto 0);
  
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
  ADD_WR => pipe2rd2_out,
  ADD_RD1 => RS1,
  ADD_RD2 => RS2,
  DATAIN => writeback_data,
  OUT1 => pipe1a_in,
  OUT2 => pipe1b_in,
  REG_FIXED_OUT => R30_OUT
);

  pipe1a: ENTITY work.REG_GENERIC
  GENERIC MAP(WIDTH => REGISTER_SIZE) PORT MAP (D => pipe1a_in, CK => CLK, RESET => RESET, Q => pipe1a_out);

  pipe1b: ENTITY work.REG_GENERIC
  GENERIC MAP(WIDTH => REGISTER_SIZE) PORT MAP (D => pipe1b_in, CK => CLK, RESET => RESET, Q => pipe1b_out);

  pipe1in1: ENTITY work.REG_GENERIC
  GENERIC MAP(WIDTH => REGISTER_SIZE) PORT MAP(D => pipe1in1_in, CK => CLK, RESET => RESET, Q => pipe1in1_out);

  pipe1in2: ENTITY work.REG_GENERIC
  GENERIC MAP(WIDTH => REGISTER_SIZE) PORT MAP(D => pipe1in2_in, CK => CLK, RESET => RESET, Q => pipe1in2_out);

  pipe1rd1: ENTITY work.REG_GENERIC GENERIC MAP(WIDTH => REG_ADDRESS_SIZE) PORT MAP(D => RD, CK => CLK, RESET => RESET, Q => pipe1rd1_out);


  --EXECUTE STAGE

  ----------------------------------------------------------------------------------------------------------------------------
  --Select the right value for read registers and overwrite register which still have not been writeback'd (data forwarding)

  --This should be a std_logic_vector assignment, no comment
  --Selection is driven from outside: 0 is "0000", 1 is real register, 2 is input from regO, 3 is regBa
  assign_values: for i in 0 to REGISTER_SIZE-1 generate

    input_for_right_a(0,i)<='0';
    input_for_right_a(1,i)<=pipe1a_out(i); --coming from RF output (will be regA operand for ALU)
    input_for_right_a(2,i)<=regO_out(i);
    input_for_right_a(3,i)<=regBa_out(i);

    input_for_right_b(0,i)<='0';
    input_for_right_b(1,i)<=pipe1b_out(i); --coming from RF output (will be regB operand for ALU)
    input_for_right_b(2,i)<=regO_out(i);
    input_for_right_b(3,i)<=regBa_out(i);
  end generate;

  which_is_right_a: ENTITY work.MUX_GENERIC
  GENERIC MAP(WIDTH => REGISTER_SIZE, HEIGHT => 4) PORT MAP(A => input_for_right_a, S => SELECT_REGA, Y => rightA_out);

  which_is_right_b: ENTITY work.MUX_GENERIC
  GENERIC MAP(WIDTH => REGISTER_SIZE, HEIGHT => 4) PORT MAP(A => input_for_right_b, S => SELECT_REGB, Y => rightB_out);
  ----------------------------------------------------------------------------------------------------------------------------


  select_immediate: ENTITY work.MUX21_GENERIC
  GENERIC MAP(WIDTH => REGISTER_SIZE) PORT MAP(A=>rightB_out, B=> pipe1in2_out, S=>S1, Y => ALU_B);

  myAlu: ENTITY work.DLX_ALU
  PORT MAP(A => rightA_out, B=> ALU_B, OP => ALU, Y => ALU_OUT, FLAGS => ALU_FLAGS_OUT, Y_extended => OPEN); 

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
  GENERIC MAP(WIDTH => REGISTER_SIZE) PORT MAP(D => pipe1b_out, CK => CLK, RESET => RESET, Q => pipe2me_out);

  pipe2rd2: ENTITY work.REG_GENERIC
  GENERIC MAP(WIDTH => REG_ADDRESS_SIZE) PORT MAP(D => pipe1rd1_out, CK => CLK, RESET => RESET, Q => pipe2rd2_out);

  MEMADDRESS <= pipe2aluout_out;
  MEMDATAIN <= pipe2me_out;
  memory_out <= MEMDATAOUT;

  mem_alu_selector: ENTITY work.MUX21_GENERIC
  GENERIC MAP(WIDTH => REGISTER_SIZE) PORT MAP(A=>pipe2aluout_out, B=> memory_out, S=> S3, Y=> writeback_data);

  --MEM/WB PIPES - What is "OUT" needed to?
  --MEM/WB STAGE

  memory: ENTITY work.MEMORY_STAGE
  PORT MAP(CLK => CLK, RESET => RESET, ADDR => pipe2aluout_out, RD_MEM => RM, WR => WM, SIGN => SIGN, LH => LH, LB => LB, DATA_IN => pipe2me_out, DATA_OUT => memory_out);
  pipe3out: ENTITY work.REG_GENERIC
  GENERIC MAP(WIDTH => REGISTER_SIZE) PORT MAP(D => writeback_data, CK => CLK, RESET => RESET, Q => pipe3out_out);


END ARCHITECTURE;

