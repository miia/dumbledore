library ieee;
use ieee.std_logic_1164.all;

package myTypes is

-- Control unit input sizes
    constant IR_SIZE : integer := 32; --size of the whole instruction (divided in [OPCODE, R1, R2, IMMEDIATE] or [OPCODE, R1, R2, R3, FUNC] )
    constant CW_SIZE : integer := 13; --number of control signals output by the Control Unit
    constant OP_CODE_SIZE : integer :=  6;                                              -- OPCODE field size
    constant REG_ADDRESS_SIZE: integer := 5;
    subtype CODE is std_logic_vector (OP_CODE_SIZE-1 downto 0);
    constant OP_INST_TYPE_SIZE : integer := 2; -- First two bits of instruction define the type
    subtype INST_TYPE is std_logic_vector(OP_INST_TYPE_SIZE-1 downto 0);
    constant OP_INST_CODE_SIZE : integer := 4;
    subtype INST_CODE is std_logic_vector(OP_INST_CODE_SIZE-1 downto 0);
    constant FUNC_SIZE : integer :=  11;                                             -- FUNC field size
    subtype FUNC is std_logic_vector(FUNC_SIZE-1 downto 0);
    subtype ALUOP is std_logic_vector(4 downto 0);
    constant ALU_FLAGS_SIZE: integer := 1;
    subtype ALU_FLAGS is std_logic_vector(ALU_FLAGS_SIZE-1 downto 0);
    subtype INSTRUCTION is std_logic_vector(IR_SIZE -1 downto 0);
    subtype REG_ADDRESS is std_logic_vector(REG_ADDRESS_SIZE-1 downto 0);

    constant REGISTER_SIZE: integer := 32;
    subtype REGISTER_CONTENT is std_logic_vector(REGISTER_SIZE-1 downto 0);

    constant CODE_ADDRESS_SIZE : integer := 32;
    subtype CODE_ADDRESS is std_logic_vector(CODE_ADDRESS_SIZE-1 downto 0);
    subtype CODE_ADDRESS_STRETCHED is std_logic_vector(CODE_ADDRESS_SIZE-2-1 downto 0);

-- R-Type instruction -> FUNC field
    constant RTYPE_ADD : std_logic_vector(FUNC_SIZE - 1 downto 0) :=  "00000000000";    -- ADD RS1,RS2,RD
    constant RTYPE_SUB : std_logic_vector(FUNC_SIZE - 1 downto 0) :=  "00000000001";    -- SUB RS1,RS2,RD
    -- ...................
    -- to be completed with the others 2 alu operation
    -- ...................
    constant NOP : std_logic_vector(FUNC_SIZE - 1 downto 0) :=  "00000000000";

-- R-Type instruction -> OPCODE field
    constant RTYPE : std_logic_vector(OP_CODE_SIZE - 1 downto 0) :=  "000000";          -- for ADD, SUB, AND, OR register-to-register operation

-- I-Type instruction -> OPCODE field
    constant ITYPE_ADDI1 : std_logic_vector(OP_CODE_SIZE - 1 downto 0) :=  "000001";    -- ADDI1 RS1,RD,INP1
    -- ...................
    -- to be completed with the others I-Type instructions
    -- ...................

    --First two bytes identify instruction
    constant OP_INST_ITYPE : INST_TYPE := "01"; 
    constant OP_INST_RTYPE : INST_TYPE := "10"; 
    constant OP_INST_HCFTYPE : INST_TYPE := "11"; 

-- Change the values of the instructions coding as you want, depending also on the type of control unit choosen

    constant OP_ITYPE_CODE_ADD1: INST_CODE := "0000";
    constant OP_ITYPE_CODE_ADD2: INST_CODE := "0001";
    --constant OP_ITYPE_CODE_ADDUI1: INST_CODE := "0000"
    constant OP_ITYPE_CODE_SUB1: INST_CODE := "0010";
    constant OP_ITYPE_CODE_SUB2: INST_CODE := "0011";
    --constant OP_ITYPE_CODE_SUBUI: INST_CODE := "0011";
    constant OP_ITYPE_CODE_AND1: INST_CODE := "0100";
    constant OP_ITYPE_CODE_AND2: INST_CODE := "0101"; -- Has been exchanged with OP_ITYPE_CODE_OR1 (should be compatible)
    constant OP_ITYPE_CODE_OR1: INST_CODE := "0111";
    constant OP_ITYPE_CODE_OR2: INST_CODE := "0110";
    --constant OP_ITYPE_CODE_XOR: INST_CODE := "0110";
    constant OP_ITYPE_CODE_MOV: INST_CODE := OP_ITYPE_CODE_ADD1; -- As it is described that for the "mov" immediate must be 0, mov and addi are equal
    constant OP_ITYPE_CODE_SREG1: INST_CODE := "1000"; -- R[R1]=INP1
    constant OP_ITYPE_CODE_SREG2: INST_CODE := "1001"; -- 
    constant OP_ITYPE_CODE_SMEM2: INST_CODE := "1010"; -- MEM[R1+INP2]=R[R2]
    constant OP_ITYPE_CODE_LMEM1: INST_CODE := "1011"; -- R[R2]=MEM[R1+INP1]
    constant OP_ITYPE_CODE_LMEM2: INST_CODE := "1100"; -- R[R2]=MEM[R1+INP2]



    constant OP_RTYPE_CODE_ADD: INST_CODE := "0000";
    constant OP_RTYPE_CODE_SUB: INST_CODE := "0000";
    constant OP_RTYPE_CODE_AND: INST_CODE := "0000";
    constant OP_RTYPE_CODE_OR: INST_CODE := "0000";

    --constant OP_RTYPE_CODE_ADDUI: INST_CODE := "0001";
    --constant OP_RTYPE_CODE_SUB: INST_CODE := "0010";
    --constant OP_RTYPE_CODE_SUBU: INST_CODE := "0011";
    --constant OP_RTYPE_CODE_AND: INST_CODE := "0100";
    --constant OP_RTYPE_CODE_OR: INST_CODE := "0101";
    --constant OP_RTYPE_CODE_XOR: INST_CODE := "0110";

    --I-TYPE FINAL OPCODES

    constant CODE_ITYPE_ADD1: CODE := OP_ITYPE_CODE_ADD1 & OP_INST_ITYPE;
    constant CODE_ITYPE_ADD2: CODE := OP_ITYPE_CODE_ADD2 & OP_INST_ITYPE;
    --constant CODITYPE_E_ADDUI1: CODE := OP_ITYPE_CODE_ADDUI1 & OP_INST_ITYPE;
    constant CODE_ITYPE_SUB1: CODE := OP_ITYPE_CODE_SUB1 & OP_INST_ITYPE;
    constant CODE_ITYPE_SUB2: CODE := OP_ITYPE_CODE_SUB2 & OP_INST_ITYPE;
    --constant CODITYPE_E_SUBUI: CODE := OP_ITYPE_CODE_SUBUI & OP_INST_ITYPE;
    constant CODE_ITYPE_AND1: CODE := OP_ITYPE_CODE_AND1 & OP_INST_ITYPE;
    constant CODE_ITYPE_AND2: CODE := OP_ITYPE_CODE_AND2 & OP_INST_ITYPE;
    constant CODE_ITYPE_OR1: CODE := OP_ITYPE_CODE_OR1 & OP_INST_ITYPE;
    constant CODE_ITYPE_OR2: CODE := OP_ITYPE_CODE_OR2 & OP_INST_ITYPE;
    --constant CODITYPE_E_XOR: CODE := OP_ITYPE_CODE_XOR & OP_INST_ITYPE;

    -- Load/Store operation
    constant CODE_ITYPE_MOV: CODE := OP_ITYPE_CODE_MOV & OP_INST_ITYPE; -- R[R1]=R[R2]
    constant CODE_ITYPE_SREG1: CODE := OP_ITYPE_CODE_SREG1 & OP_INST_ITYPE; -- R[R1]=INP1
    constant CODE_ITYPE_SREG2: CODE := OP_ITYPE_CODE_SREG2 & OP_INST_ITYPE; -- 
    constant CODE_ITYPE_SMEM2: CODE := OP_ITYPE_CODE_SMEM2 & OP_INST_ITYPE; -- MEM[R1+INP2]=R[R2]
    constant CODE_ITYPE_LMEM1: CODE := OP_ITYPE_CODE_LMEM1 & OP_INST_ITYPE; -- R[R2]=MEM[R1+INP1]
    constant CODE_ITYPE_LMEM2: CODE := OP_ITYPE_CODE_LMEM2 & OP_INST_ITYPE; -- R[R2]=MEM[R1+INP2]

    --R-TYPE FINAL OPCODES

    constant CODE_RTYPE_ADD: CODE := OP_RTYPE_CODE_ADD & OP_INST_RTYPE;
    --constant CODRTYPE_E_ADDUI: CODE := OP_RTYPE_CODE_ADDUI & OP_INST_RTYPE;
    constant CODE_RTYPE_SUB: CODE := OP_RTYPE_CODE_SUB & OP_INST_RTYPE;
    --constant CODRTYPE_E_SUBU: CODE := OP_RTYPE_CODE_SUBU & OP_INST_RTYPE;
    constant CODE_RTYPE_AND: CODE := OP_RTYPE_CODE_AND & OP_INST_RTYPE;
    constant CODE_RTYPE_OR: CODE := OP_RTYPE_CODE_OR & OP_INST_RTYPE;

    constant FUNC_ADD: FUNC := (FUNC_SIZE-1 => '0', FUNC_SIZE-2 =>'0', OTHERS => '0');
    constant FUNC_SUB: FUNC := (FUNC_SIZE-1 => '0', FUNC_SIZE-2 =>'1', OTHERS => '0');
    constant FUNC_AND: FUNC := (FUNC_SIZE-1 => '1', FUNC_SIZE-2 =>'0', OTHERS => '0');
    constant FUNC_OR: FUNC := (FUNC_SIZE-1 => '1', FUNC_SIZE-2 =>'1', OTHERS => '0');

    function optype(opcode: CODE) return INST_TYPE ;

  function r1of(inst: INSTRUCTION) return REG_ADDRESS;
  function r2of(inst: INSTRUCTION) return REG_ADDRESS;
  function r3of(inst: INSTRUCTION) return REG_ADDRESS;

  function functionof(inst: INSTRUCTION) return FUNC;
  function opcodeof(inst: INSTRUCTION) return CODE;

end myTypes;

package body myTypes is

  function optype(opcode: CODE) return INST_TYPE is --gets first 2 bits of OPCODE, to tell instruction type (R, I)
  begin
    return opcode(OP_INST_TYPE_SIZE-1 downto 0);
  end function;

  function r1of(inst: INSTRUCTION) return REG_ADDRESS is
  -- Is it possible that i have to declare this variable in order to fit into these "index bounds"? #K#?!!#@!!!
  variable puppa: std_logic_vector(REG_ADDRESS_SIZE-1 downto 0);
  begin
    puppa := inst(20+REG_ADDRESS_SIZE downto 21);
    return puppa;
  end r1of;

  function r2of(inst: INSTRUCTION) return REG_ADDRESS is
    variable puppa: std_logic_vector(REG_ADDRESS_SIZE-1 downto 0);
  begin
    puppa:= inst(15+REG_ADDRESS_SIZE downto 16);
    return puppa;
  end r2of;

  function r3of(inst: INSTRUCTION) return REG_ADDRESS is
  variable puppa: std_logic_vector(REG_ADDRESS_SIZE-1 downto 0);
  begin
    puppa:= inst(10+REG_ADDRESS_SIZE downto 11);
    return puppa;
  end r3of;

  function functionof(inst: INSTRUCTION) return FUNC is --gets FUNCTION bits from instruction
  begin
    return inst(FUNC_SIZE-1 downto 0);
  end functionof;

  function opcodeof(inst: INSTRUCTION) return CODE is --gets OPCODE bits from instruction
  variable puppa: std_logic_vector(OP_CODE_SIZE-1 downto 0);
  begin
    puppa := inst(IR_SIZE-1 downto IR_SIZE-OP_CODE_SIZE);
    return puppa;
  end opcodeof;

end myTypes;
