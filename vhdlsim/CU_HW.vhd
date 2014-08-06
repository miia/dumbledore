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
  port (
    CLK                : in  std_logic;
    RST                : in  std_logic;
    OPCODE             : in CODE; --this input will be connected to the 6 Opcode bits of the IR
    FUNC_IN              : in FUNC; --this input will be conected to the 11 Function bits of the IR
    
    -- IF Control Signals
    PC_EN   : out std_logic;         -- Program Counter Latch Enable --TODO: ONLY USED IF REGISTERS HAVE "EN" INPUT
    IR_LATCH_EN    : out std_logic;  -- Instruction Register Latch Enable --TODO: ONLY USED IF REGISTERS HAVE "EN" INPUT
    NPC_LATCH_EN   : out std_logic;  -- NPC (NextProgramCounter) Register Latch Enable --TODO: ONLY USED IF REGISTERS HAVE "EN" INPUT

    -- ID Control Signals
    RF1      : out std_logic;  -- Register A Latch Enable
    RF2      : out std_logic;  -- Register B Latch Enable
    EN1      : out std_logic;  -- Register file / Immediate Register Enable --TODO: ONLY USED IF REGISTERS HAVE "EN" INPUT

    -- EX Control Signals
    S1           : out std_logic;  -- MUX-A Sel
    S2           : out std_logic;  -- MUX-B Sel
    ALU         : out ALUOP; -- ALU Operation Code (NOTE: ALUOP TYPE = 2 BITS)
    EN2      : out std_logic;  -- ALU Output Register Enable --TODO: ONLY USED IF REGISTERS HAVE "EN" INPUT
    
    -- MEM Control Signals
    RM            : out std_logic;  -- Data Memory Read Enable
    WM            : out std_logic;  -- Data Memory Write Enable
    EN3            : out std_logic;  -- Data Memory Enable

    EN_LMD       : out std_logic;  -- LMD (Load-Memory-Data) Register Latch Enable (for register at output of Data Mem) --TODO: ONLY USED IF REGISTERS HAVE "EN" INPUT
    LH            : out std_logic;  -- these 3 signals are used to tell the Data Memory whether we want to load a Byte, Half-Word or a Word...
    LB            : out std_logic;
    SIGN          : out std_logic;  -- ...and whether we want the value to be treated as signed (=> activate sign-extension) or not.

    -- WB Control Signals
    S3         : out std_logic;  -- Write Back MUX Sel
    WF1              : out std_logic -- Register File Write Enable
  );

end DLX_CU;


architecture CU_HW of DLX_CU is

  signal IR_opcode : std_logic_vector(OP_CODE_SIZE-1 downto 0);  -- OpCode part of IR
  signal IR_func : std_logic_vector(FUNC_SIZE-1 downto 0);   -- Func part of IR when Rtype

  signal cw   : std_logic_vector(CW_SIZE-1 downto 0); -- all the control signals output by the CU to the pipeline stages of the datapath.

  -- control word is shifted to the correct stage - TODO: MODIFY THIS to reflect correct number and size of stages!!
  signal cw0 : std_logic_vector(CW_SIZE-1 downto 0);         -- all 20 control signals; a part (3) will go to stage zero (IF), the rest (17) will go to the next pipeline register
  signal cw1 : std_logic_vector(CW_SIZE-1-3 downto 0);       -- 17 control signals; a part (3) will go to stage one (ID), the rest (14) will go to the next pipeline register
  signal cw2 : std_logic_vector(CW_SIZE-1-3-3 downto 0);     -- 14 control signals; a part (5) will go to stage two (EX), the rest (9) will go to the next pipeline register
  signal cw3 : std_logic_vector(CW_SIZE-1-3-3-5 downto 0);   -- 9 control signals; a part (7) will go to stage three (MEM), the rest (2) will go to the next pipeline register
  signal cw4 : std_logic_vector(CW_SIZE-1-3-3-5-7 downto 0); -- 2 control signals, which go directly to the last pipeline stage (WB)


  --signals for the control bits going to the ALU
  --signal aluOpcode_i: aluOp := NOP; -- ALUOP defined in package
  --signal aluOpcode1: aluOp := NOP;
  --signal aluOpcode2: aluOp := NOP;
  --signal aluOpcode3: aluOp := NOP;


 
begin  -- dlx_cu_hw architecture

  IR_opcode <= OPCODE;  -- previously was IR_IN(31 downto 26);
  IR_func <= FUNC_IN;   -- previously was IR_IN(FUNC_SIZE - 1 downto 0);

  --NOTE: a part of the instruction is turned straight into control signals (immediate values, register file addresses) => they don't pass through the CU - they are just routed to their dedicated pipeline registers WITHOUT undergoing any transformation.
  --the remaining bits of the IR are instead transformed into the corresponding activation signals by the CU.

  --Statically connecting signals from output of pipeline registers to the entity output ports (going to the datapath):

  -- control signals for stage 0 (IF)
  PC_EN        <= cw0(CW_SIZE-1 - 0);
  IR_LATCH_EN  <= cw0(CW_SIZE-1 - 1);
  NPC_LATCH_EN <= cw0(CW_SIZE-1 - 2);

  -- control signals for stage 1
  RF1 <= cw1(CW_SIZE-1-3 - 0);
  RF2 <= cw1(CW_SIZE-1-3 - 1);
  EN1 <= cw1(CW_SIZE-1-3 - 2);

  -- control signals for stage 2
  S1  <= cw2(CW_SIZE-1-3-3 - 0);
  S2  <= cw2(CW_SIZE-1-3-3 - 1);
  ALU <= cw2(CW_SIZE-1-3-3 - 2 downto CW_SIZE-1-3 - 3); --NOTE: the control signals for the ALU are composed of TWO bits
  EN2 <= cw2(CW_SIZE-1-3-3 - 4);

  -- control signals for stage 3
  RM  <= cw3(CW_SIZE-1-3-3-5 - 0);
  WM  <= cw3(CW_SIZE-1-3-3-5 - 1);
  EN3 <= cw3(CW_SIZE-1-3-3-5 - 2);

  EN_LMD <= cw3(CW_SIZE-1-3-3-5 - 3);
  LH     <= cw3(CW_SIZE-1-3-3-5 - 4);
  LB     <= cw3(CW_SIZE-1-3-3-5 - 5);
  SIGN   <= cw3(CW_SIZE-1-3-3-5 - 6);

  -- control signals for stage 4
  S3  <= cw3(CW_SIZE-1-3-3-5-7 - 0);
  WF1 <= cw3(CW_SIZE-1-3-3-5-7 - 1);


  ---------------------------------------------------------------------------------------------
  -- Process to handle pipelining of control signals:                                        --
  -- this process does NOT decide the CONTENT of signals output by the CU, just their TIMING.--
  ---------------------------------------------------------------------------------------------

  CW_PIPE: process (Clk, Rst)
  begin  -- process Clk

    if Rst = '0' then              -- asynchronous reset (active low)
        cw0 <= (others => '0');
        cw1 <= (others => '0');
        cw2 <= (others => '0');
        cw3 <= (others => '0');
        cw4 <= (others => '0');
        --cw5 <= (others => '0');
        --aluOpcode1 <= NOP;
        --aluOpcode2 <= NOP;
        --aluOpcode3 <= NOP;
    elsif Clk'event and Clk = '1' then  -- rising clock edge

         cw0 <= cw;
         cw1 <= cw0(CW_SIZE-1-3 downto 0);
         cw2 <= cw1(CW_SIZE-1-3-3 downto 0);
         cw3 <= cw2(CW_SIZE-1-3-3-5 downto 0);
         cw4 <= cw3(CW_SIZE-1-3-3-5-7 downto 0);

         --aluOpcode1 <= aluOpcode_i;
         --aluOpcode2 <= aluOpcode1;
         --aluOpcode3 <= aluOpcode2;

    end if;

  end process CW_PIPE;

  --ALU_OPCODE <= aluOpcode3;

   -----------------------------------------------
   --Process to generate control signals for ALU--
   -----------------------------------------------

   --LEGEND:
   --Remember that (timing/pipelining apart) the meaning of each bit in the cw signal is:
   -- control signals for stage 1
   --cw(CW_SIZE-1 - 0) corresponds to RF1; (1 = read out of port1)
   --cw(CW_SIZE-1 - 1) corresponds to RF2; (1 = read out of port2)
   --cw(CW_SIZE-1 - 2) corresponds to EN1; (1 = enable RF + interface registers of stage1)
   -- control signals for stage 2
   --cw(CW_SIZE-1 - 3) corresponds to S1; (0 = pass output from RF)
   --cw(CW_SIZE-1 - 4) corresponds to S2; (0 = pass output from RF)
   --cw(CW_SIZE-1 - 5 downto CW_SIZE-1 - 6) are the 2 control bits for the ALU;
   --cw(CW_SIZE-1-  7) corresponds to EN2; (1 = enable interface registers of stage2)
   -- control signals for stage 3
   --cw(CW_SIZE-1 - 8) corresponds to RM;  (1 = write on Data Memory)
   --cw(CW_SIZE-1 - 9) corresponds to WM;  (1 = read from Data Memory)
   --cw(CW_SIZE-1 - 10) corresponds to EN3; (1 = enable Data Memory + interface registers of stage3)
   --cw(CW_SIZE-1 - 11) corresponds to S3; (0 = pass output from Data Memory)
   --cw(CW_SIZE-1-  12) corresponds to WF1; (1 = write on RegFile)
  
   CONTROL_SIGNALS_PROC : process (IR_opcode, IR_func)
   begin
	cw <= (others => '0'); -- default is NOP.

	case optype(IR_opcode) is --look at type of instruction (most significant 2 bits of IR_opcode)

		when OP_INST_RTYPE =>
		--instruction is R-type (=Register-Register ALU operations);
		--this means that (from left to right) the first 6 bits are the Opcode field, then 5 bits are R1, 5 bits are R2, 5 bits are R3, and 11 bits are the Function field.
		--Opcode and Function are what we'll work with inside the CU to generate the control signals (cw, 13 bits);
		--the R1,R2,R3 signals are not used inside the CU (they go directly to the Datapath input ports).

			--decide value of ALU control bits:
			case IR_func is --since the instruction is R-type, to decide the ALU activation signals we also need to look at the Function bits (=least significant 11 bits)
				when FUNC_ADD => cw(CW_SIZE-1 - 8 downto CW_SIZE-1 - 9) <= "00";  --TODO: THESE ACTIVATION SIGNALS (and also func_add, func_sub etc.) STILL HAVE TO BE DECIDED!!
				when FUNC_SUB => cw(CW_SIZE-1 - 8 downto CW_SIZE-1 - 9) <= "01";
				when FUNC_AND => cw(CW_SIZE-1 - 8 downto CW_SIZE-1 - 9) <= "10";
				when FUNC_OR  => cw(CW_SIZE-1 - 8 downto CW_SIZE-1 - 9) <= "11";
				-- in the future, other operations can be encoded by Function bits: they're 11 bits, we used only the first 2!!
				when others => NULL; --leave default bits.
			end case;

                        --TODO: isn't the "case" statement below completely useless?? the following signals should always be the same for EVERY R-type operation...

			--decide the rest of the control bits:
			case IR_opcode is --and, as always, we need to look at the content of the opcode part of the IR.
				when CODE_RTYPE_ADD => cw(CW_SIZE-1 downto CW_SIZE-1 - 4) <= "11100"; --enable RF, read using both ports, muxes pass RF outputs
						       cw(CW_SIZE-1 - 7 downto 0) <= "100011"; --enable EN2 register, do nothing with memory, mux passes EN2 register output, write back on RF.
            --REMAINING CASES ARE EQUIVALENT (the opcode field is always he same, it only specifies that the instruction is an arithmetic operation - the exact operation is specified in Function bits)
				--when CODE_RTYPE_SUB => cw(CW_SIZE-1 downto CW_SIZE-1 - 4) <= "11100";
				--		       cw(CW_SIZE-1 - 7 downto 0) <= "100011";
				--when CODE_RTYPE_AND => cw(CW_SIZE-1 downto CW_SIZE-1 - 4) <= "11100";
				--		       cw(CW_SIZE-1 - 7 downto 0) <= "100011";
				--when CODE_RTYPE_OR  => cw(CW_SIZE-1 downto CW_SIZE-1 - 4) <= "11100";
				--		       cw(CW_SIZE-1 - 7 downto 0) <= "100011";
	         when others => NULL; --leave NOP.
			end case;

		when OP_INST_ITYPE =>
		--instruction is I-type (=Load, Store, or ALU operations using an immediate value and a register);
		--this means that (from left to right) the first 6 bits are the Opcode field, then 5 bits are R1, 5 bits are R2, and 16 bits are the Immediate field.
		--so, in this case, the CU only cares about the Opcode field (6 most significant bits of IR).

			--decide all control bits by just looking at the Opcode field (even the ALU control bits: in this case, there is no Function field => they only depend on the Opcode field.)
			case IR_opcode is
				when CODE_ITYPE_ADD1 => cw <= "01110"&"00"&"100011";  --TODO: THESE ACTIVATION SIGNALS STILL HAVE TO BE DECIDED!!
				when CODE_ITYPE_SUB1 => cw <= "01110"&"01"&"100011";
				when CODE_ITYPE_AND1 => cw <= "01110"&"10"&"100011";
				when CODE_ITYPE_OR1  => cw <= "01110"&"11"&"100011";
				when CODE_ITYPE_ADD2 => cw <= "10101"&"00"&"100011";  --like ADD1, except S1 and S2 are different (ALU receives input from A,INP2 instead of INP1,B)
				when CODE_ITYPE_SUB2 => cw <= "10101"&"01"&"100011";  --same here.
				when CODE_ITYPE_AND2 => cw <= "10101"&"10"&"100011";  --same here.
				when CODE_ITYPE_OR2  => cw <= "10101"&"11"&"100011";  --same here.

			 --when CODE_ITYPE_MOV    => cw <= "10101"&"00"&"100011"; --SAME OPCODE as add1 (mov is implemented as add1 with INP1=0)
				when CODE_ITYPE_SREG1  => cw <= "00111"&"00"&"100011";
		      when CODE_ITYPE_SREG2  => cw <= "00111"&"00"&"100011";
				when CODE_ITYPE_SMEM2  => cw <= "11101"&"00"&"110100"; --sum content from regfile + INP2; use result as address to write on DataMem (writing the other content coming from regfile).
				when CODE_ITYPE_LMEM1  => cw <= "01110"&"00"&"101101"; --sum content from regfile + INP1; use result as address to read from DataMem; write result into regfile.
				when CODE_ITYPE_LMEM2  => cw <= "10101"&"00"&"101101"; --RIGHT? i'm dead, someone check this out later.
				    
				when others => NULL; --if Opcode not recognized, leave NOP.
			end case;

		-- any other instruction types in the future? (e.g. J-type)

       		when OP_INST_JTYPE => NULL; --TODO: NULL for now... add activation signals for JMP instructions.


		when others => NULL; -- leave the NOP as it is

	 end case;
   end process CONTROL_SIGNALS_PROC;


end CU_HW;
