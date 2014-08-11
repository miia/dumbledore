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
    SELECT_REGA  : out std_logic_vector(1 downto 0); --2-bit signals driving the 4-input multiplexers to implement forwarding
    SELECT_REGB  : out std_logic_vector(1 downto 0);
    ALU         : out ALUOP; -- ALU Operation Code (NOTE: ALUOP TYPE = 5 BITS)
    SIGN        : out std_logic;  -- signed/unsigned operation (if 1, activates sign extension from 16 to 32 bits)
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

  -- control word is shifted to the correct stage
  signal cw0 : std_logic_vector(CW_SIZE-1 downto 0);         -- all 20 control signals; a part (CW_IF_SIZE) will go to stage zero (IF), the rest (17) will go to the next pipeline register
  signal cw1 : std_logic_vector(CW_SIZE-1-CW_IF_SIZE downto 0);       -- 17 control signals; a part (CW_ID_SIZE) will go to stage one (ID), the rest (14) will go to the next pipeline register
  signal cw2 : std_logic_vector(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE downto 0);     -- 14 control signals; a part (CW_EX_SIZE) will go to stage two (EX), the rest (9) will go to the next pipeline register
  signal cw3 : std_logic_vector(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE downto 0);   -- 9 control signals; a part (CW_MEM_SIZE) will go to stage three (MEM), the rest (2) will go to the next pipeline register
  signal cw4 : std_logic_vector(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE-CW_MEM_SIZE downto 0); -- 2 control signals (CW_WB_SIZE), which go directly to the last pipeline stage (WB)


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

  -- control signals for stage 1 (ID)
  RF1 <= cw1(CW_SIZE-1-CW_IF_SIZE - 0);
  RF2 <= cw1(CW_SIZE-1-CW_IF_SIZE - 1);
  EN1 <= cw1(CW_SIZE-1-CW_IF_SIZE - 2);

  -- control signals for stage 2 (EX)
  S1  <= cw2(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE - 0);
  S2  <= cw2(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE - 1);
  SELECT_REGA <= cw2(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE - 2 downto CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE - 3);
  SELECT_REGB <= cw2(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE - 4 downto CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE - 5);
  ALU <= cw2(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE - 6 downto CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE - 10); --NOTE: the control signals for the ALU are composed of 5 bits
  SIGN <= cw2(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE - 11);
  EN2 <= cw2(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE - 12);

  -- control signals for stage 3 (MEM)
  RM  <= cw3(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE - 0);
  WM  <= cw3(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE - 1);
  EN3 <= cw3(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE - 2);

  EN_LMD <= cw3(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE - 3);
  LH     <= cw3(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE - 4);
  LB     <= cw3(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE - 5);
  SIGN   <= cw3(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE - 6);

  -- control signals for stage 4 (WB)
  S3  <= cw3(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE-CW_MEM_SIZE - 0);
  WF1 <= cw3(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE-CW_MEM_SIZE - 1);


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
         cw1 <= cw0(CW_SIZE-1-CW_IF_SIZE downto 0);
         cw2 <= cw1(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE downto 0);
         cw3 <= cw2(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE downto 0);
         cw4 <= cw3(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE-CW_MEM_SIZE downto 0);

         --aluOpcode1 <= aluOpcode_i;
         --aluOpcode2 <= aluOpcode1;
         --aluOpcode3 <= aluOpcode2;

    end if;

  end process CW_PIPE;

  --ALU_OPCODE <= aluOpcode3;

   -----------------------------------------------
   --Process to generate control signals for ALU--
   -----------------------------------------------

   --LEGEND (TODO: update this with the version on MS server, whenever it comes up again!):
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

	if(IR_opcode(OP_CODE_SIZE-1 downto 0) = "000000") then --all R-type instructions
	--instruction is R-type (=Register-Register operations);
	--this means that (from left to right) the first 6 bits are the Opcode field, then 5 bits are R1, 5 bits are R2, 5 bits are R3, and 11 bits are the Function field.
	--Opcode and Function are what we'll work with inside the CU to generate the control signals;
	--the operand (R1,R2,R3) signals are not used inside the CU (they go directly to the Datapath input ports).

		--1) Generate the part of activation signals that's common to all R-type instructions:

                cw(CW_SIZE-1 downto CW_SIZE-1-2) <= "111"; --enable all registers of the IF stage

                cw(CW_SIZE-1-CW_IF_SIZE downto CW_SIZE-1-CW_IF_SIZE-2) <= "111"; --enable RF and corresponding output registers in the ID stage

                cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE downto CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-5) <= "11"&"01"&"01"; --enable and pass regA and regB to ALU through muxes (by default, keep forwarding disabled; will possibly be enabled later)
                --(leave ALU and SIGN signals to be set later;)
                cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-12) <= "1";                                                   --enable ALU output register

                cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE downto CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE-6) <= "0000000"; --leave Data Memory completely unused - not activated, read and write disabled, output register disabled (Load Memory Register), etc. 

                cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE-CW_MEM_SIZE downto CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-CW_EX_SIZE-CW_MEM_SIZE-1) <= "11"; --mux passes output of ALU in the Writeback stage; Register File Write enabled.


		--2) Decide value of ALU control bits:

		--since the instruction is R-type, to decide the ALU activation signals we also need to look at the Function bits (=least significant 11 bits)
	  	case IR_func(5)&IR_func(3) is --bits 5,3 of IR tell us which of 3 R-type sub-classes the operation belongs to;
				              --this allows us to first generate a subset of signals common to that sub-class (i.e., the signals common to all R-type shift operations) before finally generating the few signals specific to the exact instruction.
				              --cleaner code FTW!
	  	when "00"      => --all R-type shift operations

                        --generate signals common to all shift instructions:
                        cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-6 downto CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-7) <= "00"; --the upper 2 bits of ALU output are NOT used; set them to zero
                        cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-11) <= "0";                                           --the SIGN output is NOT used; set it to zero

	    		--now look at bits 1,0 of IR (of IR_func) for exact instruction and generate specific signals.
                        case IR_func(1 downto 0) is
			when "00" => -- SLL
                                     cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-8 downto CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-10) <= "111"; --Logical; Shift; Left
			when "10" => -- SRL
                                     cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-8 downto CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-10) <= "110"; --Logical; Shift; Right
			when "11" => -- SRA
                                     cw(CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-8 downto CW_SIZE-1-CW_IF_SIZE-CW_ID_SIZE-10) <= "010"; --Arithmetic; Shift; Right
			when others => NULL; --if Opcode not recognized, leave NOP.
                        end case;

	  	when "10"      => --all R-type arith/logic operations
	    		--(TODO: generate common signals to all arithmetic/logic operations)
	    		--(TODO: now look at bits 2,1,0 of IR (of IR_func) for exact instruction and generate specific signals.)

	  	when "01"|"11" => --all R-type set operations (further subdivision possible here: bit 4 of IR tells if the comparison must be signed or unsigned.)
	    		--(TODO: generate common signals to all set operations)
	    		--(TODO: now look at bits 2,1,0 of IR (of IR_func) for exact instruction and generate specific signals.
		   	--DO IT IN PAIRS: if slt|sltu, then generate certain signals; if sgt|sgtu, then generate certain signals; and so on... then you'll finally set bit 4 to drive the "unsigned" pin of the comparator.)
	    		--(TODO: as last activation signal, drive bit 4 of IR (of IR_func) directly to drive the "unsigned" pin of the comparator block.)

	  	when others => NULL; --panic! TODO: something like an error assertion could be useful here during testing.
	  	end case;


	elsif(IR_opcode(OP_CODE_SIZE-1 downto OP_CODE_SIZE-1-2) = "000") then --first 3 bits of Opcode field tell us this is an I-type branch or jump instruction (i.e., with an immediate operand, to be added to PC+4)
                                                                              --I-type => from left to right, the first 6 bits are the Opcode field, then 5 bits are R1, 5 bits are R2, and 16 bits are the Immediate field.

  		--(TODO: generate common signals to all branch or jump operations)
  		--(TODO: look at bit 28 of IR (bit 2 of IR_opcode) to see if it's a branch (conditional) of just a jmp (unconditional); if the bit is 1 (branch), generate the additional signals needed by a branch and not by a jmp.
         	--that is: the branches need the additional configuration of the branch unit, etc...)
  		--(TODO: now look at bits 27,26 of IR (bits 1,0 of IR_opcode) for exact instruction and generate specific signals.)


	elsif(IR_opcode(OP_CODE_SIZE-1 downto OP_CODE_SIZE-1-3) = "0101") then --bits 4 bits of Opcode field tell us this is an I-type shift instruction
                                                                               --(i.e. a shift, but with immediate source; the R-type shift instructions, instead, have already been covered above)
                                                                               --I-type => from left to right, the first 6 bits are the Opcode field, then 5 bits are R1, 5 bits are R2, and 16 bits are the Immediate field.

		--(TODO: generate common signals to all shift operations)
		--(TODO: now look at bits 27,26 of IR (bits 1,0 of IR_opcode) for exact instruction and generate specific signals.)

	--elsif(ir(xx downto yy) = zzzz) then --LOAD/STORE (TODO.)
	--
	--


	elsif(IR_opcode(OP_CODE_SIZE-1 downto OP_CODE_SIZE-1-2) = "001") then --some more I-type instructions: either lhi, or an arithmetic/logic instruction with immediate operand
                                                                              --I-type => from left to right, the first 6 bits are the Opcode field, then 5 bits are R1, 5 bits are R2, and 16 bits are the Immediate field.

                 --(WARNING/TODO: lhi is covered in this "if" too, so maybe (depending on ISA) all other load/stores will be included here as well, and a sub-condition will distinguish between load/stores and arith/logic) 

		--(TODO: generate activation signals common to all lhi AND arithmetic/logic operations)
		--(TODO: distinguish betweeh lhi and arithmetic/logic instruction; generate respective signals)
		--(TODO: look at bits 28-27-26 of IR (bits 2-1-0 of IR_opcode) for exact instruction and generate specific signals.)

                --OLD EXAMPLE:
		--decide all control bits by just looking at the Opcode field (even the ALU control bits: in this case, there is no Function field => they only depend on the Opcode field.)
		--case IR_opcode is
		--	when CODE_ITYPE_ADD1 => cw <= "01110"&"00"&"100011";
		--	when CODE_ITYPE_SUB1 => cw <= "01110"&"01"&"100011";
		--	when CODE_ITYPE_AND1 => cw <= "01110"&"10"&"100011";
		--	when CODE_ITYPE_OR1  => cw <= "01110"&"11"&"100011";
		--	when CODE_ITYPE_ADD2 => cw <= "10101"&"00"&"100011";  --like ADD1, except S1 and S2 are different (ALU receives input from A,INP2 instead of INP1,B)
		--	when CODE_ITYPE_SUB2 => cw <= "10101"&"01"&"100011";  --same here.
		--	when CODE_ITYPE_AND2 => cw <= "10101"&"10"&"100011";  --same here.
		--	when CODE_ITYPE_OR2  => cw <= "10101"&"11"&"100011";  --same here.

		--      when CODE_ITYPE_MOV    => cw <= "10101"&"00"&"100011"; --SAME OPCODE as add1 (mov is implemented as add1 with INP1=0)
		--	when CODE_ITYPE_SREG1  => cw <= "00111"&"00"&"100011";
	      	--	when CODE_ITYPE_SREG2  => cw <= "00111"&"00"&"100011";
		--	when CODE_ITYPE_SMEM2  => cw <= "11101"&"00"&"110100"; --sum content from regfile + INP2; use result as address to write on DataMem (writing the other content coming from regfile).
		--	when CODE_ITYPE_LMEM1  => cw <= "01110"&"00"&"101101"; --sum content from regfile + INP1; use result as address to read from DataMem; write result into regfile.
		--	when CODE_ITYPE_LMEM2  => cw <= "10101"&"00"&"101101"; --RIGHT? i'm dead, someone check this out later.
			    
		--	when others => NULL; --if Opcode not recognized, leave NOP.
		--end case;




	-- TODO: any other instruction types in the future?

	else => NULL; -- leave the NOP as it is

	end if;

   end process CONTROL_SIGNALS_PROC;


end CU_HW;
