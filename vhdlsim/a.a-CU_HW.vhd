library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use work.myTypes.all;
--use ieee.numeric_std.all;
--use work.all;

entity DLX_CU is
    --NO GENERICS HERE: moved to the myTypes package as constants, to handle them from a single location.
--  generic (
--    FUNC_SIZE          :     integer := 11;  -- Func Field Size for R-Type Ops
--    OP_CODE_SIZE       :     integer := 6;  -- Op Code Size
--    IR_SIZE            :     integer := 32;  -- Instruction Register Size    
--    CW_SIZE            :     integer := 15);  -- Control Word Size
  generic (
    DEBUG_MODE : boolean := true  --enables or disables "printing" debug text on an additional output port (just for simulation purposes: all the additional debug logic will get IGNORED during synthesis by setting DEBUG_MODE to false).
          );
  port (
    CLK                : in  std_logic;
    RST                : in  std_logic;
    OPCODE             : in CODE; --this input will be connected to the 6 Opcode bits of the IR
    FUNC_IN            : in FUNC; --this input will be conected to the 11 Function bits of the IR

    PRED               : in std_logic; --this input is the prediction for a Branch instruction that was computed into the fetch stage; it should get into the EX stage to let it know which formula to use to compute the fallback adddress (if PRED=1 => fallback computed as PC+0; if PRED=0 => fallback computed as PC+Immediate from branch instruction).
    FLUSH_PIPELINE    : in std_logic; --When this input is active (high), the control word entering stage 2 (EX) is changed to a NOP.
    
    -- IF Control Signals
    PC_EN   : out std_logic;         -- Program Counter Latch Enable --TODO: ONLY USED IF REGISTERS HAVE "EN" INPUT
    IR_LATCH_EN    : out std_logic;  -- Instruction Register Latch Enable --TODO: ONLY USED IF REGISTERS HAVE "EN" INPUT
    NPC_LATCH_EN   : out std_logic;  -- NPC (NextProgramCounter) Register Latch Enable --TODO: ONLY USED IF REGISTERS HAVE "EN" INPUT

    -- ID Control Signals
    RF1      : out std_logic;  -- Register A Latch Enable
    RF2      : out std_logic;  -- Register B Latch Enable
    EN1      : out std_logic;  -- Register file / Immediate Register Enable --TODO: ONLY USED IF REGISTERS HAVE "EN" INPUT

    -- EX Control Signals
    S1           : out std_logic;  -- MUX-A Sel (the one between current PC value and rightA_out (from the big mux of the A operand, see schematic))
    S2           : out std_logic;  -- MUX-B Sel (the one between Immediate operand and rightB_out (from the big mux of the B operand, see schematic))
    SELECT_REGA  : out std_logic_vector(1 downto 0); --2-bit signals driving the big 4-input multiplexers to implement forwarding
    SELECT_REGB  : out std_logic_vector(1 downto 0);
    ALU         : out ALUOP; -- ALU Operation Code (NOTE: ALUOP TYPE = 9 BITS)
    SIGN_EX        : out std_logic;  -- signed/unsigned operation (if 1, activates sign extension from 16 to 32 bits)
    EN2      : out std_logic;  -- ALU Output Register Enable --TODO: ONLY USED IF REGISTERS HAVE "EN" INPUT
    
    -- MEM Control Signals
    RM            : out std_logic;  -- Data Memory Read Enable
    WM            : out std_logic;  -- Data Memory Write Enable
    EN3            : out std_logic;  -- Data Memory Enable

    EN_LMD       : out std_logic;  -- LMD (Load-Memory-Data) Register Latch Enable (for register at output of Data Mem) --TODO: ONLY USED IF REGISTERS HAVE "EN" INPUT
    LH            : out std_logic;  -- these 3 signals are used to tell the Data Memory whether we want to load a Byte, Half-Word or a Word...
    LB            : out std_logic;
    SIGN_MEM          : out std_logic;  -- ...and whether we want the value to be treated as signed (=> activate sign-extension) or not.

    -- WB Control Signals
    S3         : out std_logic;  -- Write Back MUX Sel
    WF1              : out std_logic; -- Register File Write Enable

    -- additional debug port - will be used in simulation with DEBUG_MODE=1
    DEBUG      : out string(6 downto 1) --should be long enough for any instruction mnemonic...
  );

end DLX_CU;


architecture CU_HW of DLX_CU is

  signal IR_opcode : std_logic_vector(OP_CODE_SIZE-1 downto 0);  -- OpCode part of IR
  signal IR_func : std_logic_vector(FUNC_SIZE-1 downto 0);   -- Func part of IR when Rtype

  signal cw   : std_logic_vector(CW_SIZE-1 downto 0); -- all the control signals output by the CU to the pipeline stages of the datapath.
                                                      -- these are all the 20 control signals; a part (CW_IF_SIZE) will go to stage zero (IF), the rest (17) will go to the next pipeline register
  -- control word is shifted to the correct stage
  --signal cw0 : std_logic_vector(CW_SIZE-1 downto 0);         -- all 20 control signals; a part (CW_IF_SIZE) will go to stage zero (IF), the rest (17) will go to the next pipeline register
  signal cw1, cw1_latched : std_logic_vector(CW_SIZE-1-CW_IF_SIZE downto 0);       -- 17 control signals; a part (CW_ID_SIZE) will go to stage one (ID), the rest (14) will go to the next pipeline register
  signal cw2, cw1_or_nop : std_logic_vector(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE downto 0);     -- 14 control signals; a part (CW_EX_SIZE) will go to stage two (EX), the rest (9) will go to the next pipeline register
  signal cw3, cw3_latched : std_logic_vector(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE downto 0);   -- 9 control signals; a part (CW_MEM_SIZE) will go to stage three (MEM), the rest (2) will go to the next pipeline register
  signal cw4 : std_logic_vector(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE-CW_MEM_SIZE downto 0); -- 2 control signals (CW_WB_SIZE), which go directly to the last pipeline stage (WB)


  --signals for the control bits going to the ALU
  --signal aluOpcode_i: aluOp := NOP; -- ALUOP defined in package
  --signal aluOpcode1: aluOp := NOP;
  --signal aluOpcode2: aluOp := NOP;
  --signal aluOpcode3: aluOp := NOP;

  --signal IR_func_5_and_3 : std_logic_vector(1 downto 0); --VHDL doesn't allow "case IR_func(5)&IR_func(3) is ...", so we have to first route them to a separate signal and then perform the CASE statement on that.
 
begin  -- dlx_cu_hw architecture
    
  --IR_func_5_and_3 <= IR_func(5)&IR_func(3); --the stupid fix - see above

  IR_opcode <= OPCODE;  -- previously was IR_IN(31 downto 26);
  IR_func <= FUNC_IN;   -- previously was IR_IN(FUNC_SIZE - 1 downto 0);

  --NOTE: a part of the instruction is turned straight into control signals (immediate values, register file addresses) => they don't pass through the CU - they are just routed to their dedicated pipeline registers WITHOUT undergoing any transformation.
  --the remaining bits of the IR are instead transformed into the corresponding activation signals by the CU.

  --Statically connecting signals from output of pipeline registers to the entity output ports (going to the datapath):

  -- control signals for stage 0 (IF)
  PC_EN        <= cw(CW_SIZE-1 - 0);
  IR_LATCH_EN  <= cw(CW_SIZE-1 - 1);
  NPC_LATCH_EN <= cw(CW_SIZE-1 - 2);

  -- control signals for stage 1 (ID)
  RF1 <= cw1_latched(CW_SIZE-1-CW_IF_SIZE - 0);
  RF2 <= cw1_latched(CW_SIZE-1-CW_IF_SIZE - 1);
  EN1 <= cw1_latched(CW_SIZE-1-CW_IF_SIZE - 2) or cw4(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE-CW_MEM_SIZE - 1); -- Enable can be enabled by either the control word OR the write signal of three instructions before (or both)

  -- control signals for stage 2 (EX)
  S1  <= cw2(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE - 0);
  S2  <= cw2(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE - 1);
  SELECT_REGA <= cw2(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE - 2 downto CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE - 3);
  SELECT_REGB <= cw2(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE - 4 downto CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE - 5);
  ALU <= cw2(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE - 6 downto CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE - 14); --NOTE: the control signals for the ALU are composed of 9 bits
  SIGN_EX <= cw2(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE - 15);
  EN2 <= cw2(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE - 16);

  -- control signals for stage 3 (MEM)
  RM  <= cw3_latched(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE - 0);
  WM  <= cw3_latched(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE - 1);
  EN3 <= cw3_latched(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE - 2);

  EN_LMD     <= cw3_latched(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE - 3);
  LH         <= cw3_latched(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE - 4);
  LB         <= cw3_latched(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE - 5);
  SIGN_MEM   <= cw3_latched(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE - 6);

  -- control signals for stage 4 (WB)
  S3  <= cw3(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE-CW_MEM_SIZE - 0);
  WF1 <= cw4(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE-CW_MEM_SIZE - 1);

  --------------------------------------------------------------------------------------------
  --Management for flush signals of the pipeline:                                           --
  --Before entering EX stage (i.e. cw2), the control word can be changed to that of a NOP.  --
  --To do this, this MUX is used.                                                           --
  --------------------------------------------------------------------------------------------
  select_cw1_or_nop: ENTITY work.MUX21_GENERIC
  GENERIC MAP(WIDTH => CW_SIZE-CW_IF_SIZE-CW_ID_SIZE) PORT MAP(A => NOP_SIGNALS(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE downto 0), B => cw1(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE downto 0), S => FLUSH_PIPELINE, Y => cw1_or_nop); 

  ---------------------------------------------------------------------------------------------
  -- Process to handle pipelining of control signals:                                        --
  -- this process does NOT decide the CONTENT of signals output by the CU, just their TIMING.--
  ---------------------------------------------------------------------------------------------

  -- CW4 will be latched instead of flip-flop'd to respect setup time of register file. Cw1 is doubled because flip-flop'd cw1 must go into cw pipe (cw2)
  cw1_latch: ENTITY work.LATCH_GENERIC
  GENERIC MAP(WIDTH => CW_SIZE-CW_IF_SIZE) PORT MAP(CLK => CLK, RESET => RST, D => cw(CW_SIZE-1-CW_IF_SIZE downto 0), Q => cw1_latched);
  cw3_latch : ENTITY work.LATCH_GENERIC
  GENERIC MAP(WIDTH => CW_SIZE-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE) PORT MAP(CLK => CLK, RESET => RST, D => cw2(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE downto 0), Q => cw3_latched);
  cw4_latch: ENTITY work.LATCH_GENERIC
  GENERIC MAP(WIDTH => CW_SIZE-CW_IF_SIZE-CW_ID_SIZE -CW_EX_SIZE-CW_MEM_SIZE)
  PORT MAP(CLK => CLK, RESET => RST, D => cw3(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE-CW_MEM_SIZE downto 0), Q => cw4);

  CONTROL_SIGNALS_PROC: process (Clk, Rst, IR_opcode, IR_func)
  begin  -- process Clk

    if Rst = '0' then              -- asynchronous reset (active low)
        cw <= (others => '0');
        cw1 <= (others => '0');
        cw2 <= (others => '0');
        cw3 <= (others => '0');
        PRINT(DEBUG_MODE, "(RST) ", DEBUG);  -- content of PRINT procedure gets completely ignored if DEBUG_MODE=false (see procedure body)


        --cw5 <= (others => '0');
        --aluOpcode1 <= NOP;
        --aluOpcode2 <= NOP;
        --aluOpcode3 <= NOP;
    else
        if Clk'event and Clk = '1' then  -- rising clock edge: go on with pipe

           --cw0 <= cw;
           cw1 <= cw(CW_SIZE-1-CW_IF_SIZE downto 0);
           cw2 <= cw1_or_nop(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE downto 0); -- CW2 can be changed to a NOP with a command
           cw3 <= cw2(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE downto 0);
           --aluOpcode1 <= aluOpcode_i;
           --aluOpcode2 <= aluOpcode1;
           --aluOpcode3 <= aluOpcode2;
        end if;


    --ALU_OPCODE <= aluOpcode3;

     -----------------------------------------------
     --Process to generate control signals for ALU--
     -----------------------------------------------

     --LEGEND:
     --Remember that (timing/pipelining apart) the meaning of each bit in the cw signal is:
     -- control signals for stage 0 (IF)
     --cw(CW_SIZE-1 - 0) corresponds to PC_EN;          (1 = enable Program Counter register)
     --cw(CW_SIZE-1 - 1) corresponds to IR_LATCH_EN;    (1 = enable IR Register)
     --cw(CW_SIZE-1 - 2) corresponds to NPC_LATCH_EN;   (1 = enable New Program Counter register)

     -- control signals for stage 1 (ID)
     --cw(CW_SIZE-1-CW_IF_SIZE - 0) corresponds to RF1; (1 = read out of port1)
     --cw(CW_SIZE-1-CW_IF_SIZE - 1) corresponds to RF2; (1 = read out of port2)
     --cw(CW_SIZE-1-CW_IF_SIZE - 2) corresponds to EN1; (1 = enable RF and interface registers of stage1)

     -- control signals for stage 2 (EX)
     --cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE - 0) corresponds to S1; (0 = pass output from RF out of multiplexer S1; 1 = pass value of PC)
     --cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE - 1) corresponds to S2; (0 = pass output from RF out of multiplexer S2; 1 = pass value of Immediate coming from IR)
     --cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE - 2 downto CW_SIZE-1 - 3) correspond to SELECT_REGA;  ("00"=> all zeroes; "01"=> output A from RF; "10" => Output register (1st forwarding register); "11" => Backup register (2nd forwarding register).)
     --cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE - 4 downto CW_SIZE-1 - 5) correspond to SELECT_REGB;  ("00"=> all zeroes; "01"=> output B from RF; "10" => Output register (1st forwarding register); "11" => Backup register (2nd forwarding register).)
     --cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE - 6 downto CW_SIZE-1 - 14) are the 9 control bits for the ALU;
     --cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE - 15) corresponds to SIGN_EX; (1 = Signed version of operations take place in the ALU; 0 = Unsigned version)
     --cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE  16) corresponds to EN2; (1 = enable interface registers of stage2)

     -- control signals for stage 3 (MEM)
     --cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE - 0) corresponds to RM;  (1 = write on Data Memory (for store instructions))
     --cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE - 1) corresponds to WM;  (1 = read from Data Memory (for load instructions))
     --cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE - 2) corresponds to EN3; (1 = enable Data Memory)
     --cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE - 3) corresponds to EN_LMD (1 = enable Load Memory output register (for Load operations, enables the Data Memory output register. Not needed for Store operations on the Data Memory...))
     --cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE - 4) corresponds to LH   (LH,LB = "00" => load/store a word from Data Memory; "10"=>load/store a half word; "11"=> load/store a byte.)
     --cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE - 5) corresponds to LB   (LH,LB = "00" => load/store a word from Data Memory; "10"=>load/store a half word; "11"=> load/store a byte.)
     --cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE - 6) corresponds to SIGN_MEM (1 = in case of a Load from datamem, treat the the loaded value as signed => perform sign extension on 32-bits.)

     --control signals for stage 4 (WB)
     --cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE-CW_MEM_SIZE - 0) corresponds to S3; (0 = pass output from Data Memory)
     --cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE-CW_MEM_SIZE - 1) corresponds to WF1 (and implicitly also activates EN1 - see the signal going into EN1 above); (1 = write on RegFile)

      cw <= NOP_SIGNALS; -- DEFAULT ASSIGNMENT: nop. this is necessary because even the recognized instructions will not set every single bit of the control word.
      PRINT(DEBUG_MODE, "NOP   ", DEBUG);  -- content of PRINT procedure gets completely ignored if DEBUG_MODE=false (see procedure body)


      if(IR_opcode(OP_CODE_SIZE-1 downto 0) = "000000") then --all R-type instructions
      --instruction is R-type (=Register-Register operations);
      --this means that (from left to right) the first 6 bits of IR are the Opcode field, then 5 bits are R1, 5 bits are R2, 5 bits are R3, and 11 bits are the Function field.
      --Opcode and Function are what we'll work with inside the CU to generate the control signals;
      --the operand (R1,R2,R3) signals are not used inside the CU (they go directly to the Datapath input ports).

        --1) Generate the part of activation signals that's common to all R-type instructions:

            cw(CW_SIZE-1 downto CW_SIZE-1-2) <= "111"; --enable all registers of the IF stage

            cw(CW_SIZE-1-CW_IF_SIZE downto CW_SIZE-1-CW_IF_SIZE-2) <= "111"; --enable RF and corresponding output registers in the ID stage

            cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE downto CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-5) <= "00"&"01"&"01"; --enable and pass regA and regB to ALU through muxes (by default, keep forwarding disabled; will possibly be enabled later)
            --(leave ALU and SIGN_EX signals to be set later;)
            cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-16) <= '1';                                                   --enable ALU output register

            cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE downto CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE-6) <= "0000000"; --leave Data Memory completely unused - not activated, read and write disabled, output register disabled (Load Memory Register), etc. 

            cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE-CW_MEM_SIZE downto CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE-CW_MEM_SIZE-1) <= "11"; --mux passes output of ALU in the Writeback stage; Register File Write enabled.


        --2) Decide value of ALU control bits:

        --since the instruction is R-type, to decide the ALU activation signals we also need to look at the Function bits of IR (=least significant 11 bits)
          case IR_func(5 downto 3) is --bits 5,3 of IR tell us which of 3 R-type sub-classes the operation belongs to; THE MIDDLE BIT (4) is ignored here.
                          --this allows us to first generate a subset of signals common to that sub-class (i.e., the signals common to all R-type shift operations) before finally generating the few signals specific to the exact instruction.
                          --cleaner code FTW!
          when "000"|"010"      => --(5,3)=(0,0) => all R-type shift operations

                --generate signals common to all shift operations:
                cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-9) <= '0'; -- bit 5 of ALU control signals can pre-select within ALU between LH output and logic unit output; unused, set it to zero (logic unit).

                cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-10 downto CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-11) <= "10"; --bits 4,3 of ALU control signal select shifter in the output mux within the ALU.

                cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-15) <= '0'; --the SIGN_EX output is NOT used; set it to zero

              --now look at bits 1,0 of IR (of IR_func) for exact instruction and generate specific signals.
                case IR_func(1 downto 0) is
                when "00" => -- SLL
                                         cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-12 downto CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-14) <= "111"; --Logical; Shift; Left
                                         PRINT(DEBUG_MODE, "SLL   ", DEBUG);  -- content of PRINT procedure gets completely ignored if DEBUG_MODE=false (see procedure body)
                when "10" => -- SRL
                                         cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-12 downto CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-14) <= "110"; --Logical; Shift; Right
                                         PRINT(DEBUG_MODE, "SRL   ", DEBUG);  -- content of PRINT procedure gets completely ignored if DEBUG_MODE=false (see procedure body)
                when "11" => -- SRA
                                         cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-12 downto CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-14) <= "010"; --Arithmetic; Shift; Right
                                         PRINT(DEBUG_MODE, "SRA   ", DEBUG);  -- content of PRINT procedure gets completely ignored if DEBUG_MODE=false (see procedure body)

                when others => cw <= NOP_SIGNALS; --instruction is not recognized, fall back to NOP.
                               PRINT(DEBUG_MODE, "??????", DEBUG);  -- content of PRINT procedure gets completely ignored if DEBUG_MODE=false (see procedure body)
                end case;

          when "100"|"110"      => --(5,3)=(1,0) => all R-type arith/logic operations

              --generate common signals to all arithmetic/logic operations:
              cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-9) <= '0'; --bit 5 of ALU control signals can pre-select within ALU between LH output and logic unit output; set it to zero (logic unit).

              --now look at bits 2,1,0 of IR (of IR_func) for exact instruction and generate specific signals.
              case IR_func(2) is
              when '0' => --it's an arithmetic (ADD/SUB) operation;

                    cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-10 downto CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-11) <= "00"; --needs the ADD/SUB block of the ALU to be selected in the output mux inside the ALU. generate corresponding signal.

                    case IR_func(1 downto 0) is  --NOTE: right now the SIGN_EX bit is only used to extend the Immediate field (=> only used in ADDI, ADDUI, SUBI, SUBUI etc.)
                                                 --      that's because there are no carry flag, overflow flag or similar generated by the ALU
                                                 --      => with the following 4 instructions, SIGN_EX is driven just for (possible) future use.
                    when "00" => -- ADD
                                          cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-13 downto CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-14) <= "10"; --select output of adder/subtractor, request addition
                                          cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-15) <= '1';                                           --signed.
                                          PRINT(DEBUG_MODE, "ADD   ", DEBUG);  -- content of PRINT procedure gets completely ignored if DEBUG_MODE=false (see procedure body)

                    when "01" => -- ADDU
                                          cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-13 downto CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-14) <= "10"; --select output of adder/subtractor, request addition
                                          cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-15) <= '0';                                           --unsigned.
                                          PRINT(DEBUG_MODE, "ADDU  ", DEBUG);  -- content of PRINT procedure gets completely ignored if DEBUG_MODE=false (see procedure body)
                    when "10" => -- SUB
                                          cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-13 downto CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-14) <= "11"; --select output of adder/subtractor, request subtraction
                                          cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-15) <= '1';                                           --signed.
                                          PRINT(DEBUG_MODE, "SUB   ", DEBUG);  -- content of PRINT procedure gets completely ignored if DEBUG_MODE=false (see procedure body)

                    when "11" => -- SUBU
                                          cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-13 downto CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-14) <= "11"; --select output of adder/subtractor, request subtraction
                                          cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-15) <= '0';                                           --unsigned.
                                          PRINT(DEBUG_MODE, "SUBU  ", DEBUG);  -- content of PRINT procedure gets completely ignored if DEBUG_MODE=false (see procedure body)


                    when others => cw <= NOP_SIGNALS; --instruction is not recognized, fall back to NOP.
                                   PRINT(DEBUG_MODE, "??????", DEBUG);  -- content of PRINT procedure gets completely ignored if DEBUG_MODE=false (see procedure body)
                    end case;

                when '1' => --it's a logic operation;

                    cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-10 downto CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-11) <= "01"; --needs the Logic block of the ALU to be selected in the output mux inside the ALU. generate corresponding signal.

                    case IR_func(1 downto 0) is

                    when "00" => -- AND
                                cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-13 downto CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-14) <= "01"; --select AND
                                PRINT(DEBUG_MODE, "AND   ", DEBUG);  -- content of PRINT procedure gets completely ignored if DEBUG_MODE=false (see procedure body)
                    when "01" => -- OR
                                cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-13 downto CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-14) <= "00"; --select OR
                                PRINT(DEBUG_MODE, "OR    ", DEBUG);  -- content of PRINT procedure gets completely ignored if DEBUG_MODE=false (see procedure body)
                    when "10" => -- XOR
                                cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-13 downto CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-14) <= "10"; --select XOR
                                PRINT(DEBUG_MODE, "XOR   ", DEBUG);  -- content of PRINT procedure gets completely ignored if DEBUG_MODE=false (see procedure body)

                    when others => cw <= NOP_SIGNALS; --instruction is not recognized, fall back to NOP.
                                   PRINT(DEBUG_MODE, "??????", DEBUG);  -- content of PRINT procedure gets completely ignored if DEBUG_MODE=false (see procedure body)
                    end case;

                when others => cw <= NOP_SIGNALS; --instruction is not recognized, fall back to NOP.
                               PRINT(DEBUG_MODE, "??????", DEBUG);  -- content of PRINT procedure gets completely ignored if DEBUG_MODE=false (see procedure body)
                end case;

          when "001"|"101"|"011"|"111" => --(bit 3)=1 => all R-type set operations (further subdivision possible here: bit 4 of IR tells if the comparison must be signed or unsigned.)

              --generate common signals to all set operations:

              cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-9) <= '0'; --bit 5 of ALU control signals can pre-select within ALU between LH output and logic unit output; unused, set it to zero (logic unit).

              cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-10 downto CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-11) <= "11"; --needs the Logic block of the ALU to be selected in the output mux inside the ALU. generate corresponding signal.

              --configure ALU's arithmetic unit for register-register subtraction (take same activation signals as R-type subtraction above).
              cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-14) <= '1'; --pre-select output of adder/subtractor within arithmetic unit, request subtraction
              cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-13) <= not IR_func(4); --use bit 4 of IR (of IR_func) directly to drive the "signed" pin of the arithmetic unit block
              cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-15) <= not IR_func(4); --use bit 4 of IR (of IR_func) directly to drive the "unsigned" pin of the sign extension block


              --now look at bits 2,1,0 of IR (of IR_func) for exact instruction, and generate specific signals (to configure the Compare unit).
              --THIS IS DONE IN PAIRS: slt|sltu will have identical signals (signed/unsigned has already been taken care of); same for sgt|sgtu, etc.

              case IR_func(2 downto 0) is
              when "000" => -- SEQ
                          cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-6 downto CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-8) <= "010";
                          PRINT(DEBUG_MODE, "SEQ   ", DEBUG);  -- content of PRINT procedure gets completely ignored if DEBUG_MODE=false (see procedure body)
              when "001" => -- SNE
                          cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-6 downto CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-8) <= "011";
                          PRINT(DEBUG_MODE, "SNE   ", DEBUG);  -- content of PRINT procedure gets completely ignored if DEBUG_MODE=false (see procedure body)
              when "010" => -- SLT/SLTU
                          cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-6 downto CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-8) <= "000";
                          PRINT(DEBUG_MODE, "SLT(U)", DEBUG);  -- content of PRINT procedure gets completely ignored if DEBUG_MODE=false (see procedure body)
              when "011" => -- SGT/SGTU
                          cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-6 downto CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-8) <= "101";
                          PRINT(DEBUG_MODE, "SGT(U)", DEBUG);  -- content of PRINT procedure gets completely ignored if DEBUG_MODE=false (see procedure body)
              when "100" => -- SLE/SLEU
                          cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-6 downto CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-8) <= "001";
                          PRINT(DEBUG_MODE, "SLE(U)", DEBUG);  -- content of PRINT procedure gets completely ignored if DEBUG_MODE=false (see procedure body)
              when "101" => -- SGE/SGEU
                          cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-6 downto CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-8) <= "100";
                          PRINT(DEBUG_MODE, "SGE(U)", DEBUG);  -- content of PRINT procedure gets completely ignored if DEBUG_MODE=false (see procedure body)
              when others => cw <= NOP_SIGNALS; --instruction is not recognized, fall back to NOP.
                             PRINT(DEBUG_MODE, "??????", DEBUG);  -- content of PRINT procedure gets completely ignored if DEBUG_MODE=false (see procedure body)
              end case;


          when others => cw <= NOP_SIGNALS; --instruction is not recognized, fall back to NOP.
                         PRINT(DEBUG_MODE, "??????", DEBUG);  -- content of PRINT procedure gets completely ignored if DEBUG_MODE=false (see procedure body)
          end case;


      elsif(IR_opcode(OP_CODE_SIZE-1 downto OP_CODE_SIZE-1-2) = "000") then --first 3 bits of Opcode field tell us this is an I-type branch or jump instruction (i.e., with an immediate operand, to be added to PC+4)
                                                                            --this means J, JAL, BEQZ, or BNEZ.
                                                                            --I-type => from left to right, first 6 bits of IR are the Opcode field, then 5 bits are R1, 5 bits are R2, and 16 bits are the Immediate field.


          -- Do not generate the signals common to all I-type instructions, because jump/branch instructions (J and JAL, BEZ and BNEZ) are a particulare case: they DON'T REQUIRE the same activation signals as all other I-type instructions (e.g.: for Jump instructions, the fetch_stage autonomously computes the target address and updates the PC; for Branch instructions, the destination of the ALU output is not the register file, but rather the PC (or actually the branch unit).... and so on).
          -- The only signals common to all these 4 instructions are "keep the fetch stage going as usual":
          cw(CW_SIZE-1 downto CW_SIZE-1-2) <= "111"; --enable all registers of the IF stage

          --Look at bit 28 of IR (bit 2 of IR_opcode) to see if it's a branch (conditional, i.e. BEZ or BNEZ) of just a jmp (unconditional, i.e.J or JAL);
          case IR_opcode(OP_CODE_SIZE-1-3) is

          when '0' => -- J or JAL
                      -- NOTE: jump instructions DON'T use the ALU to compute the target address and update the PC - that's all done by the fetch stage autonomously.
                      -- the CU is only responsible for the "additional" functions (e.g. JAL => the CU just worries about saving the value of PC+4 in register r30).


              PRINT(DEBUG_MODE, "J(AL) ", DEBUG);  -- content of PRINT procedure gets completely ignored if DEBUG_MODE=false (see procedure body)


              --now look at bits 27,26 of IR (bits 1,0 of IR_opcode) for exact instruction and generate specific signals:
              case IR_opcode(OP_CODE_SIZE-1-4 downto OP_CODE_SIZE-1-5) is
              when "10" => -- J instruction.
                          NULL; -- J instruction needs NOTHING from the CU - it just has to sit there => leave NOP.
              when "11" => -- JAL instruction. similar to J, with the addition of saving PC+4 value in register R30.
                          cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE - 0) <= '1'; --pass PC value into ALU from muxA;

                          cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE - 1) <= '0'; --pass rightB_out into ALU from muxB;
                          cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE - 4 downto CW_SIZE-1 -CW_IF_SIZE-CW_ID_SIZE- 5) <= "00"; --rightB_out will be "000...00"; TODO: shouldn't the constant value be 4 instead of 0?? we need to do PC+4...

                          cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-10 downto CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-11) <= "00"; --needs the ADD/SUB block of the ALU to be selected in the output mux inside the ALU. generate corresponding signal.
                          cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-13 downto CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-14) <= "11"; --select output of adder/subtractor, request addition (=> result is PC+4).

                          cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-16) <= '1'; --enable ALU output register

                          cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE-CW_MEM_SIZE downto CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE-CW_MEM_SIZE-1) <= "11"; --mux passes output of ALU in the Writeback stage; Register File Write enabled.
                          --^NOTE: when the above instruction is recognized, the fetch_stage also recognizes it and automatically overrides the DESTINATION input of the regfile to be r31 (decentralized control) => the CU doesn't need to set the destination register address from here.

              when others => cw <= NOP_SIGNALS; --instruction is not recognized, fall back to NOP.
             end case;

          when '1' => -- BEZ or BNEZ
                      -- NOTE: in the case of BEZ or BNEZ, the ALU is in charge of computing the fallback address (which will then go from the ALU output to the Branch Unit);
                      -- in BOTH cases (bez or bnez), the activation signals will be exactly the same!!
                      -- but the CU needs to do 2 things:
                      -- 1) compute the fallback address (whose formula depends on the prediction that the BPU had performed earlier in the fetch stage: either fallback <= PC+4 if predicted taken, or fallback <= PC+4+Immediate otherwise). To compute imm+PC+4 (as PC is truncated - last 2 bits are implicit), we compute imm-((not PC) & 11)
                      -- 2) send the register to be checked along the rightA_out signal (because the Branch Unit will check its value and decide whether it should jump to the fallback address + flush the pipeline).


                      PRINT(DEBUG_MODE, "B(N)EZ", DEBUG);  -- content of PRINT procedure gets completely ignored if DEBUG_MODE=false (see procedure body)


                      --Common signals to both Branch instructions:
                      cw(CW_SIZE-1-CW_IF_SIZE - 0) <= '1'; -- Enable read of regA
                      cw(CW_SIZE-1-CW_IF_SIZE - 2) <= '1'; --enable regfile output registers (and also Immediate register);

                      --pass appropriate register through rightA_out (will be read by Branch Unit inside fetch_stage):
                      cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE - 2 downto CW_SIZE-1 -CW_IF_SIZE-CW_ID_SIZE- 3) <= "01"; --select value from regfile output A; the RS1 field of the Branch instruction will automatically select the appropriate register from the RF
             
                      cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE - 0) <= '1';   --pass PC value into ALU from muxA (always needed to compute the Fallback address);
                      --cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-16) <= '1';  --enable ALU output register TODO: not needed, right?

                      cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-13 downto CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-14) <= "11"; -- ALU configuration: select output from adder/subtractor, request subtraction


                      case PRED is -- Note that the prediction entering the CU is actually inverted - the fetch stage informs the cu of what prediction *THE CU* shall compute (i.e. the wrong one)

                      when '1' => --branch was predicted as not taken => compute fallback addr as PC + Imm
                                  cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE - 1) <= '1'; --pass Immediate value into ALU from muxB;
                                  cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE - 15) <= '1';  --we want to perform SIGNED addition (=> extend the Immediate value as a signed integer).

                      when '0' => --branch was predicted as taken => compute fallback addr as PC + 0
                                  cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE - 1) <= '0'; --pass rightB_out into ALU from muxB;
                                  cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE - 4 downto CW_SIZE-1 -CW_IF_SIZE-CW_ID_SIZE- 5) <= "00"; --rightB_out will be "000...00"; TODO: shouldn't the constant value be 4 instead of 0?? we need to do PC+4...

                      when others => cw <= NOP_SIGNALS; --instruction is not recognized, fall back to NOP.
                                     PRINT(DEBUG_MODE, "??????", DEBUG);  -- content of PRINT procedure gets completely ignored if DEBUG_MODE=false (see procedure body)

                  end case;

          when others => cw <= NOP_SIGNALS; --instruction is not recognized, fall back to NOP.
                         PRINT(DEBUG_MODE, "??????", DEBUG);  -- content of PRINT procedure gets completely ignored if DEBUG_MODE=false (see procedure body)

      end case;



      elsif(IR_opcode(OP_CODE_SIZE-1 downto OP_CODE_SIZE-1-3) = "0101") then --first 4 bits of Opcode field tell us this is an I-type shift instruction
                                                                               --(i.e. a shift, but with immediate source; the R-type shift instructions, instead, have already been covered above)
                                                                               --I-type => from left to right, first 6 bits of IR are the Opcode field, then 5 bits are R1, 5 bits are R2, and 16 bits are the Immediate field.

          --generate common signals to all I-type operations
          cw(CW_SIZE-1 downto CW_SIZE-1-2) <= "111"; --enable all registers of the IF stage

          cw(CW_SIZE-1-CW_IF_SIZE downto CW_SIZE-1-CW_IF_SIZE-2) <= "111"; --enable RF and corresponding output registers in the ID stage

          cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE downto CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-5) <= "01"&"01"&"01"; --muxes will pass regA and the immediate operand (by default, keep forwarding disabled; will possibly be enabled later)
                    --(leave ALU and _EX signals to be set later;)
          cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-16) <= '1';                                                  --enable ALU output register

          cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE downto CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE-6) <= "0000000"; --leave Data Memory completely unused - not activated, read and write disabled, output register disabled (Load Memory Register), etc. 

          cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE-CW_MEM_SIZE downto CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE-CW_MEM_SIZE-1) <= "11"; --mux passes output of ALU in the Writeback stage; Register File Write enabled.


          --generate common signals to all shift operations
          cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-10 downto CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-11) <= "10"; --bits 4,3 of ALU control signal select shifter in the output mux within the ALU.

          --now look at bits 27,26 of IR (bits 1,0 of IR_opcode) for exact instruction and generate specific signals.

          case IR_opcode(1 downto 0) is
          when "00" => -- SLLI (Shift Left Logical - immediate)
                       cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-12 downto CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-14) <= "111"; --Logical; Shift; Left
                       PRINT(DEBUG_MODE, "SLLI  ", DEBUG);  -- content of PRINT procedure gets completely ignored if DEBUG_MODE=false (see procedure body)
          when "01" => -- NOP (?? if NOP is implemented like a 0-bits shift, isn't it possible that a NOP causes a stall due to a RAW hazard? maybe it's the COMPILER's responsibility *wink* to choose a register != from the destination register of the previous instruction.)
                       cw <= NOP_SIGNALS; --TODO: implement as shift if necessary.
                       PRINT(DEBUG_MODE, "NOP   ", DEBUG);  -- content of PRINT procedure gets completely ignored if DEBUG_MODE=false (see procedure body)
          when "10" => -- SRLI (Shift Right Logical - immediate)
                       cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-12 downto CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-14) <= "110"; --Logical; Shift; Right
                       PRINT(DEBUG_MODE, "SRLI  ", DEBUG);  -- content of PRINT procedure gets completely ignored if DEBUG_MODE=false (see procedure body)
          when "11" => -- SRAI (Shift Right Arithmetic - immediate)
                       cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-12 downto CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-14) <= "010"; --Arithmetic; Shift; Right
                       PRINT(DEBUG_MODE, "SRAI  ", DEBUG);  -- content of PRINT procedure gets completely ignored if DEBUG_MODE=false (see procedure body)
          when others => cw <= NOP_SIGNALS; --instruction is not recognized, fall back to NOP.
                         PRINT(DEBUG_MODE, "??????", DEBUG);  -- content of PRINT procedure gets completely ignored if DEBUG_MODE=false (see procedure body)

          end case;



      elsif(IR_opcode(OP_CODE_SIZE-1 downto OP_CODE_SIZE-1-1) = "10") then --first 2 bits of Opcode field tell us this is an I-type LOAD or STORE instruction.
                                                                           --I-type => from left to right, first 6 bits of IR are the Opcode field, then 5 bits are R1, 5 bits are R2, and 16 bits are the Immediate field.
          --generate common signals to all I-type operations
          cw(CW_SIZE-1 downto CW_SIZE-1-2) <= "111"; --enable all registers of the IF stage

          cw(CW_SIZE-1-CW_IF_SIZE downto CW_SIZE-1-CW_IF_SIZE-2) <= "111"; --enable RF and corresponding output registers in the ID stage

          cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE downto CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-5) <= "01"&"01"&"01"; --muxes will pass regA and the immediate operand (by default, keep forwarding disabled; will possibly be enabled later)
                                                                                                          --(leave ALU and _EX signals to be set later;)
          cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-16) <= '1';                                                  --enable ALU output register
          --configure ALU and EX-stage muxes for addition between regA and Imm (to get the load/store datamem address)
          cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-10 downto CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-11) <= "00"; --selects the Arithmetic (adder-subtractor) block of the ALU in the output mux inside the ALU.
          cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-13 downto CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-14) <= "10"; --select output of adder/subtractor, request addition
          cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-15) <= '1';                                            --signed.

          --NOT THIS TIME:
          --cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE downto CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE-6) <= "0000000"; --leave Data Memory completely unused - not activated, read and write disabled, output register disabled (Load Memory Register), etc.

          --NOT THIS TIME:
          --cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE-CW_MEM_SIZE downto CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE-CW_MEM_SIZE-1) <= "11"; --mux passes output of ALU in the Writeback stage; Register File Write enabled.
          --^only in the case of a Store, the regfile will be written, and the output of the DATA MEM will be selected by the S3 mux instead of the ALU output.

          --generate signals common to all Load/Store operations:
          cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE-2) <= '1'; --enable Data Memory. (all the rest of the MEM stage signals will depend on whether it is a Load or a Store instruction)
          
          --look at bit 29 of IR (bit 3 of IR_opcode) to see whether it is a load instruction or a store instruction, and generate common signals:
          case IR_opcode(3) is

          when '0' => --instruction is a load: activate read from Data Memory + enable LMD output latch register, configure S3 and WF1 for writeback from datamem to register file.

              --generate signals common to all load instructions:
              cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE - 0) <= '1';  --activate read from Data Memory (the value pointed to by the ALU result will be read)
              cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE - 3) <= '1';   --enable LMD output latch register
              cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE-CW_MEM_SIZE - 0) <= '0'; --configure S3 to pass output from Data Memory;
              cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE-CW_MEM_SIZE - 1) <= '1'; --activate Write on regfile (the value read bt Data Memory will be written to the register specified by the RD field of the instruction.)

              --now look at bits 28,27,26 of IR (bits 2,1,0 of IR_opcode) for exact Load instruction and generate specific signals (= configure LB/LH/SIGN_MEM depending on specific instruction).
              case IR_opcode(2 downto 0) is

              when "000" => --LB
                           cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE - 4 downto CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE - 5) <= "11"; --load Byte
                           cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE - 6) <= '1'; --signed extension (to Word size) of the read value
                           PRINT(DEBUG_MODE, "LB    ", DEBUG);  -- content of PRINT procedure gets completely ignored if DEBUG_MODE=false (see procedure body)

              when "001" => --LH
                           cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE - 4 downto CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE - 5) <= "10"; --load Half-word
                           cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE - 6) <= '1'; --signed extension (to Word size) of the read value
                           PRINT(DEBUG_MODE, "LH    ", DEBUG);  -- content of PRINT procedure gets completely ignored if DEBUG_MODE=false (see procedure body)

              when "011" => --LW
                           cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE - 4 downto CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE - 5) <= "00"; --load Word
                           PRINT(DEBUG_MODE, "LW    ", DEBUG);  -- content of PRINT procedure gets completely ignored if DEBUG_MODE=false (see procedure body)

              when "100" => --LBU
                           cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE - 4 downto CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE - 5) <= "11"; --load Byte
                           cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE - 6) <= '0'; --unsigned extension (to Word size) of the read value
                           PRINT(DEBUG_MODE, "LBU   ", DEBUG);  -- content of PRINT procedure gets completely ignored if DEBUG_MODE=false (see procedure body)
                           
              when "101" => --LHU
                           cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE - 4 downto CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE - 5) <= "10"; --load Half-word
                           cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE - 6) <= '0'; --unsigned extension (to Word size) of the read value
                           PRINT(DEBUG_MODE, "LHU   ", DEBUG);  -- content of PRINT procedure gets completely ignored if DEBUG_MODE=false (see procedure body)
                           
              --when "110" => --LF(floating point not implemented)
                       
              --when "111" => --LD(double precision not implemented)
                               
              when others => 
                           cw <= NOP_SIGNALS; --instruction is not recognized, fall back to NOP.
                           PRINT(DEBUG_MODE, "??????", DEBUG);  -- content of PRINT procedure gets completely ignored if DEBUG_MODE=false (see procedure body)
              end case;

          when '1' => --instruction is a store: select regB as rightB_out (will go to DataMem input as the value to be stored), activate write on Data Memory. (no need to configure LMD register, load signals, or writeback signals.)

              --generate signals common to all store instructions:
              cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE - 4 downto CW_SIZE-1 -CW_IF_SIZE-CW_ID_SIZE- 5) <= "01"; --select regB as rightB_out (will go to DataMem input as the value to be stored)
              cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE - 1) <= '1';  --activate write on Data Memory (so that the value carried by rightB_out will be written on the address computed by the ALU.)

              --now look at bits 28,27,26 of IR (bits 2,1,0 of IR_opcode) for exact Store instruction and generate specific signals.
              case IR_opcode(2 downto 0) is
              when "011" => --SW
                           NULL; --right now, store WORD is the only store that's supported => nothing to configure further.
                           PRINT(DEBUG_MODE, "SW    ", DEBUG);  -- content of PRINT procedure gets completely ignored if DEBUG_MODE=false (see procedure body)
              when others => --throw an error if anything else is requested.
                           cw <= NOP_SIGNALS; --instruction is not recognized, fall back to NOP.
                           PRINT(DEBUG_MODE, "??????", DEBUG);  -- content of PRINT procedure gets completely ignored if DEBUG_MODE=false (see procedure body)
              end case;

          when others => cw <= NOP_SIGNALS; --instruction is not recognized, fall back to NOP.
                         PRINT(DEBUG_MODE, "??????", DEBUG);  -- content of PRINT procedure gets completely ignored if DEBUG_MODE=false (see procedure body)
          end case;

      elsif(IR_opcode(OP_CODE_SIZE-1 downto OP_CODE_SIZE-1-2) = "001") then --first 3 bits of Opcode field tell us this is an I-type arithmetic/logic instruction (i.e. arithmetic/logic with immediate operand, including LHI).
                                                                              --I-type => from left to right, first 6 bits of IR are the Opcode field, then 5 bits are R1, 5 bits are R2, and 16 bits are the Immediate field.

            --(WARNING: lhi is covered here because it's an I-type instruction, while lh, lhu, sh and all other R-type load/stores are covered elsewhere.)

          --generate common signals to all I-type operations
            cw(CW_SIZE-1 downto CW_SIZE-1-2) <= "111"; --enable all registers of the IF stage

            cw(CW_SIZE-1-CW_IF_SIZE downto CW_SIZE-1-CW_IF_SIZE-2) <= "111"; --enable RF and corresponding output registers in the ID stage

            cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE downto CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-5) <= "01"&"01"&"01"; --muxes will pass regA and the immediate operand (by default, keep forwarding disabled; will possibly be enabled later)
                    --(leave ALU and SIGN_EX signals to be set later;)
            cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-16) <= '1';                                                  --enable ALU output register

            cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE downto CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE-6) <= "0000000"; --leave Data Memory completely unused - not activated, read and write disabled, output register disabled (Load Memory Register), etc. 

            cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE-CW_MEM_SIZE downto CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE-CW_MEM_SIZE-1) <= "11"; --mux passes output of ALU in the Writeback stage; Register File Write enabled.


        --distinguish between arithmetic vs lhi/logic instruction; generate respective signal for the big output mux of the ALU.
            case IR_opcode(2) is
            when '0' => --addi, addui, subi, or subui instruction (=> select adder-subtractor in the big output mux).

                      cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-10 downto CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-11) <= "00"; --needs the Arithmetic (adder-subtractor) block of the ALU to be selected in the output mux inside the ALU. generate corresponding signal.

                      --look at bits 28-27-26 of IR (bits 2-1-0 of IR_opcode) for exact instruction and generate specific signals.
                      case IR_opcode(1 downto 0) is
                      when "00" => --ADDI

                                  cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-13 downto CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-14) <= "10"; --select output of adder/subtractor, request addition
                                  cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-15) <= '1';                                            --signed.
                                  PRINT(DEBUG_MODE, "ADDI  ", DEBUG);  -- content of PRINT procedure gets completely ignored if DEBUG_MODE=false (see procedure body)

                                  
                      when "01" => --ADDUI

                                  cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-13 downto CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-14) <= "10"; --select output of adder/subtractor, request addition
                                  cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-15) <= '0';                                            --unsigned.
                                  PRINT(DEBUG_MODE, "ADDUI ", DEBUG);  -- content of PRINT procedure gets completely ignored if DEBUG_MODE=false (see procedure body)

                      when "10" => --SUBI

                                  cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-13 downto CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-14) <= "11"; --select output of adder/subtractor, request subtraction
                                  cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-15) <= '1';                                            --signed.
                                  PRINT(DEBUG_MODE, "SUBI  ", DEBUG);  -- content of PRINT procedure gets completely ignored if DEBUG_MODE=false (see procedure body)

                      when "11" => --SUBUI
                                  
                                  cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-13 downto CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-14) <= "11"; --select output of adder/subtractor, request subtraction
                                  cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-15) <= '0';                                            --unsigned.
                                  PRINT(DEBUG_MODE, "SUBUI ", DEBUG);  -- content of PRINT procedure gets completely ignored if DEBUG_MODE=false (see procedure body)
                      when others =>
                                  cw <= NOP_SIGNALS; --instruction is not recognized, fall back to NOP.
                                  PRINT(DEBUG_MODE, "??????", DEBUG);  -- content of PRINT procedure gets completely ignored if DEBUG_MODE=false (see procedure body)

                      end case;

          when '1' => --andi, ori, xori, or lhi instruction (=> select logic/lh in the big output mux).

                      cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-10 downto CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-11) <= "01"; --needs the Logic (or LH) block of the ALU to be selected in the output mux inside the ALU. generate corresponding signal.

                      --look at bits 28-27-26 of IR (bits 2-1-0 of IR_opcode) for exact instruction and generate specific signals.
                      case IR_opcode(1 downto 0) is
                      when "00" => --ANDI
                                  cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-9) <= '0'; -- pre-select Logic unit: bit 5 of ALU control signals can pre-select within ALU between LH output and logic unit output; set it to zero (logic unit).
                                  cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-13 downto CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-14) <= "01"; --select AND
                                  PRINT(DEBUG_MODE, "ANDI  ", DEBUG);  -- content of PRINT procedure gets completely ignored if DEBUG_MODE=false (see procedure body)

                      when "01" => --ORI
                                  cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-9) <= '0'; -- pre-select Logic unit: bit 5 of ALU control signals can pre-select within ALU between LH output and logic unit output; set it to zero (logic unit).
                                  cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-13 downto CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-14) <= "00"; --select OR
                                  PRINT(DEBUG_MODE, "ORI   ", DEBUG);  -- content of PRINT procedure gets completely ignored if DEBUG_MODE=false (see procedure body)


                      when "10" => --XORI
                                  cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-9) <= '0'; -- pre-select Logic unit: bit 5 of ALU control signals can pre-select within ALU between LH output and logic unit output; set it to zero (logic unit).
                                  cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-13 downto CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-14) <= "10"; --select XOR
                                  PRINT(DEBUG_MODE, "XORI  ", DEBUG);  -- content of PRINT procedure gets completely ignored if DEBUG_MODE=false (see procedure body)

                      when "11" => --LHI
                                  cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-9) <= '1'; -- pre-select LH unit: bit 5 of ALU control signals can pre-select within ALU between LH output and logic unit output; set it to one (LH unit).
                                  --nothing else to do here; LH block doesn't need any configuration - it just outputs the only possible result.
                                  PRINT(DEBUG_MODE, "LHI   ", DEBUG);  -- content of PRINT procedure gets completely ignored if DEBUG_MODE=false (see procedure body)

                      when others =>
                                  cw <= NOP_SIGNALS; --instruction is not recognized, fall back to NOP.
                                  PRINT(DEBUG_MODE, "??????", DEBUG);  -- content of PRINT procedure gets completely ignored if DEBUG_MODE=false (see procedure body)
                      end case;
                      
                      
          when others =>
                      cw <= NOP_SIGNALS; --instruction is not recognized, fall back to NOP.
                      PRINT(DEBUG_MODE, "??????", DEBUG);  -- content of PRINT procedure gets completely ignored if DEBUG_MODE=false (see procedure body)

                      
          end case;

    elsif(IR_opcode(OP_CODE_SIZE-1 downto OP_CODE_SIZE-1-3)="0100") then -- first 4 bits of Opcode field tell us this is a JR instruction or equivalent - RFE, TRAP, JR, JALR. Only JR is implemented.
        --generate common signals to all JR-type operations
          cw(CW_SIZE-1 downto CW_SIZE-1-2) <= "111"; --enable all registers of the IF stage

          cw(CW_SIZE-1-CW_IF_SIZE downto CW_SIZE-1-CW_IF_SIZE-2) <= "101"; --enable RF and corresponding output register A in the ID stage
          cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE downto CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE-6) <= "0000000"; --leave Data Memory completely unused - not activated, read and write disabled, output register disabled (Load Memory Register), etc. 

          cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE-CW_MEM_SIZE downto CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE-CW_MEM_SIZE-1) <= "10"; --mux passes output of ALU in the Writeback stage; Register File Write disabled.

          cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE downto CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-5) <= "01"&"01"&"01"; --muxes will pass regA and the immediate operand (by default, keep forwarding disabled; will possibly be enabled later)
          if(IR_opcode(OP_CODE_SIZE-1-4 downto OP_CODE_SIZE-1-5)="10") then
            cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-16) <= '1';                                                  --enable ALU output register
            cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-10 downto CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-11) <= "00"; --needs the Arithmetic (adder-subtractor) block of the ALU to be selected in the output mux inside the ALU. generate corresponding signal.
            cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-12) <= '1'; --select output of adder/subtractor, request NOP

            PRINT(DEBUG_MODE, "JR    ", DEBUG);  -- content of PRINT procedure gets completely ignored if DEBUG_MODE=false (see procedure body)
          else
           cw <= NOP_SIGNALS; --instruction is not recognized, fall back to NOP. -- TODO: first handle any other instruction types? (any instructions that can't be recognized using one of the above patterns.)
           PRINT(DEBUG_MODE, "??????", DEBUG);  -- content of PRINT procedure gets completely ignored if DEBUG_MODE=false (see procedure body)
         end if;
     elsif(IR_opcode(4 downto 3)="11") then-- All I-Type set instructions
      --generate common signals to all set operations:
      cw(CW_SIZE-1 downto CW_SIZE-1-2) <= "111"; --enable all registers of the IF stage

      cw(CW_SIZE-1-CW_IF_SIZE downto CW_SIZE-1-CW_IF_SIZE-2) <= "101"; --enable RF and corresponding output register A in the ID stage
      cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE downto CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE-6) <= "0000000"; --leave Data Memory completely unused - not activated, read and write disabled, output register disabled (Load Memory Register), etc. 

      cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE-CW_MEM_SIZE downto CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE-CW_MEM_SIZE-1) <= "10"; --mux passes output of ALU in the Writeback stage; Register File Write disabled.

      cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE downto CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-5) <= "01"&"01"&"01"; --muxes will pass regA and the immediate operand (by default, keep forwarding disabled; will possibly be enabled later)

      cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-9) <= '0'; --bit 5 of ALU control signals can pre-select within ALU between LH output and logic unit output; unused, set it to zero (logic unit).

      cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-10 downto CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-11) <= "11"; --needs the Logic block of the ALU to be selected in the output mux inside the ALU. generate corresponding signal.

      --configure ALU's arithmetic unit for register-register subtraction (take same activation signals as R-type subtraction above).
      cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-13) <= not IR_opcode(5); --use bit 5 of IR_opcode directly to drive the "signed" pin of the arithmetic unit block
      cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-14) <= '1'; --pre-select output of adder/subtractor within arithmetic unit, request subtraction
      cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-15) <= not IR_opcode(5); --use bit 5 of IR_opcode) directly to drive the "signed" pin of the sign extension block
      cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE downto CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE-6) <= "0000000"; --leave Data Memory completely unused - not activated, read and write disabled, output register disabled (Load Memory Register), etc. 

      cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE-CW_MEM_SIZE downto CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE-CW_MEM_SIZE-1) <= "11"; --mux passes output of ALU in the Writeback stage; Register File Write enabled.


      --now look at bits 2,1,0 of IR (of IR_func) for exact instruction, and generate specific signals (to configure the Compare unit).
      --THIS IS DONE IN PAIRS: slt|sltu will have identical signals (signed/unsigned has already been taken care of); same for sgt|sgtu, etc.

      case IR_opcode(2 downto 0) is
      when "000" => -- SEQ
                  cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-6 downto CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-8) <= "010";
                  PRINT(DEBUG_MODE, "SEQI  ", DEBUG);  -- content of PRINT procedure gets completely ignored if DEBUG_MODE=false (see procedure body)
      when "001" => -- SNE
                  cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-6 downto CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-8) <= "011";
                  PRINT(DEBUG_MODE, "SNEI  ", DEBUG);  -- content of PRINT procedure gets completely ignored if DEBUG_MODE=false (see procedure body)
      when "010" => -- SLT/SLTU
                  cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-6 downto CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-8) <= "000";
                  PRINT(DEBUG_MODE, "SLI(U)", DEBUG);  -- content of PRINT procedure gets completely ignored if DEBUG_MODE=false (see procedure body)
      when "011" => -- SGT/SGTU
                  cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-6 downto CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-8) <= "101";
                  PRINT(DEBUG_MODE, "SGI(U)", DEBUG);  -- content of PRINT procedure gets completely ignored if DEBUG_MODE=false (see procedure body)
      when "100" => -- SLE/SLEU
                  cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-6 downto CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-8) <= "001";
                  PRINT(DEBUG_MODE, "SLE(i)", DEBUG);  -- content of PRINT procedure gets completely ignored if DEBUG_MODE=false (see procedure body)
      when "101" => -- SGE/SGEU
                  cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-6 downto CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-8) <= "100";
                  PRINT(DEBUG_MODE, "SGE(i)", DEBUG);  -- content of PRINT procedure gets completely ignored if DEBUG_MODE=false (see procedure body)
      when others => cw <= NOP_SIGNALS; --instruction is not recognized, fall back to NOP.
                  PRINT(DEBUG_MODE, "??????", DEBUG);  -- content of PRINT procedure gets completely ignored if DEBUG_MODE=false (see procedure body)
      end case;
    else
           cw <= NOP_SIGNALS; --instruction is not recognized, fall back to NOP. -- TODO: first handle any other instruction types? (any instructions that can't be recognized using one of the above patterns.)
           PRINT(DEBUG_MODE, "??????", DEBUG);  -- content of PRINT procedure gets completely ignored if DEBUG_MODE=false (see procedure body)

      end if;
    end if;

  end process CONTROL_SIGNALS_PROC;


end CU_HW;
