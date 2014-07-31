library ieee;
use ieee.std_logic_1164.all;
use work.myTypes.all;

entity DLX_CU is
  port (
    CLK                : in  std_logic;
    RST                : in  std_logic;
    OPCODE             : in CODE;
    FUNC_IN             : in FUNC;
    
    -- ID Control Signals
    RF1      : out std_logic;  -- Register A Latch Enable
    RF2      : out std_logic;  -- Register B Latch Enable
    EN1      : out std_logic;  -- Register file / Immediate Register Enable

    -- EX Control Signals
    S1           : out std_logic;  -- MUX-A Sel
    S2           : out std_logic;  -- MUX-B Sel
    -- ALU Operation Code
    ALU         : out ALUOP; 
    EN2      : out std_logic;  -- ALU Output Register Enable
    
    -- MEM Control Signals
    RM            : out std_logic;  -- Data RAM Read Enable
    WM            : out std_logic;  -- Data RAM Write Enable
    EN3            : out std_logic;  -- Data RAM Enable

    -- WB Control signals
    S3         : out std_logic;  -- Write Back MUX Sel
    WF1              : out std_logic
  );  -- Register File Write Enable

end DLX_CU;

architecture CU_FSM of DLX_CU is
  constant MICROCODE_MEM_SIZE: natural := 14;
  constant CW_SIZE : integer := 8;
  type mem_array is array (integer range 0 to MICROCODE_MEM_SIZE - 1) of std_logic_vector(CW_SIZE - 1 downto 0);
    
  --                      RF1-RF2-S1-S2-RM-WM-S3-WF
  signal cw_mem : mem_array := ("11100011", -- R type - anything
                                "01000011", -- ADDI1/MOV
                                "10110011", -- ADDI2
                                "01000011", -- SUBI1
                                "10110011", -- SUBI2
                                "01000011", -- ANDI1
                                "10110011", -- ANDI2
                                "01000011", -- ORI1
                                "10110011", -- ORI2
                                --L/S
                                "00010011", -- SREG1
                                "00010011", -- SREG2 -- implemented as ADDI Rx, 0, Imm - R0 being
                                "10110100", -- SMEM2
                                "01001001", -- LMEM1
                                "10111001" -- LMEM2
                              );
                                
  type state is (
    reset,
    go,
    fetch,
    decode,
    execute,
    writeback
  );
  signal currentCode: CODE;
  signal currentFunc: FUNC;
  signal controlWord: std_logic_vector(CW_SIZE-1 downto 0);

  signal currentState: state;
  signal regfile_cw: std_logic_vector(2 downto 0); -- Used to flip the read/write registers enable

begin

  reg_rw_control: process(currentState)
  begin
    if(currentState=decode) then
      RF1<=regfile_cw(2);
      RF2<=regfile_cw(1);
      WF1<='0';
    elsif(currentState=writeback) then
      RF1<='0';
      RF2<='0';
      WF1<=regfile_cw(0);
    else
      RF1<='0';
      RF2<='0';
      WF1<='0';
    end if;
  end process;

  currentState_machine: process(CLK, RST)
  begin
   if (RST='1' and CLK='1' and CLK'event) then
    case currentState is
      when reset =>
        currentState <= fetch;
        EN1 <= '1';
        EN2 <= '0';
        EN3 <= '0';
      when fetch =>
        currentState<=execute;
        EN1 <= '0';
        EN2 <= '1';
        EN3 <= '0';
      when execute =>
        currentState<=writeback;
        EN1 <= '0';
        EN2 <= '0';
        EN3 <= '1';
      when writeback =>
        currentState<=fetch;
        EN1 <= '1';
        EN2 <= '0';
        EN3 <= '0';
      when others => NULL;
    end case;
   elsif(RST='0') then
         currentState <= reset;
         EN1 <= '0';
         EN2 <= '0';
         EN3 <= '0';
   end if;
  end process;

  --Fetch a single instruction, updates current{Code,Func}
  fetchdecode_manager: process(currentState)
  variable tmpCode: CODE;
  begin
    if (currentState=fetch and RST='1') then
      tmpCode := OPCODE;
      currentCode<=tmpCode;
      currentFunc<=FUNC_IN;
    end if;
    case tmpCode is
            when CODE_RTYPE_ADD => controlWord <= cw_mem(0);
            --when CODE_RTYPE_SUB => controlWord <= cw_mem(0); --These cases are already covered by the first one (same opcode)
            --when CODE_RTYPE_AND => controlWord <= cw_mem(0);
            --when CODE_RTYPE_OR  => controlWord <= cw_mem(0);
            when CODE_ITYPE_ADD1 => controlWord <= cw_mem(1);
            --when CODE_ITYPE_MOV => controlWord <= cw_mem(1); --Idem con patate
            when CODE_ITYPE_ADD2 => controlWord <= cw_mem(2);
            when CODE_ITYPE_SUB1 => controlWord <= cw_mem(3);
            when CODE_ITYPE_SUB2 => controlWord <= cw_mem(4);
            when CODE_ITYPE_AND1 => controlWord <= cw_mem(5);
            when CODE_ITYPE_AND2 => controlWord <= cw_mem(6);
            when CODE_ITYPE_OR1 => controlWord <= cw_mem(7);
            when CODE_ITYPE_OR2 => controlWord <= cw_mem(8);
            when CODE_ITYPE_SREG1 => controlWord <= cw_mem(9);
            when CODE_ITYPE_SREG2 => controlWord <= cw_mem(10);
            when CODE_ITYPE_SMEM2 => controlWord <= cw_mem(11);
            when CODE_ITYPE_LMEM1 => controlWord <= cw_mem(12);
            when CODE_ITYPE_LMEM2 => controlWord <= cw_mem(13);
            when OTHERS => NULL;
      end case;
  end process;

  --Selects the correct alu operation into the decode phase
  aluop_mux: process(currentCode, currentFunc)
  begin
    if(opType(currentCode)=OP_INST_RTYPE) then
      ALU <= currentFunc(1 downto 0);
    else
      if(currentCode(OP_CODE_SIZE-1)='1') then -- We have a load/store instruction
        ALU <= "00";
      else
        ALU <= currentCode(OP_CODE_SIZE-2 downto OP_CODE_SIZE-3); -- Opcodes are placed so that the alu function is coded into the middle 2 bits
      end if;
    end if;
  end process;

  decode_manager: process(currentState)
  begin
    if (currentState=decode) then
      
    end if;
  end process;

  --Copypasted from port declaration
    regfile_cw(2)  <= controlWord(7);
    regfile_cw(1)  <= controlWord(6);
           
    S1   <= controlWord(5);
    S2   <= controlWord(4);
          
    RM   <= controlWord(3);
    WM   <= controlWord(2);

    S3   <= controlWord(1);
    regfile_cw(0)  <= controlWord(0);

end CU_FSM;
