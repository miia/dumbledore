library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.myTypes.all;
use work.ceillog.all;

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

architecture CU_UP of DLX_CU is
  constant MICROCODE_MEM_SIZE: natural := 256;
  constant CW_SIZE : integer := 12;
  type mem_array is array (integer range 0 to MICROCODE_MEM_SIZE - 1) of std_logic_vector(CW_SIZE - 1 downto 0);
    
  --Opcode=6bits, x3 clock cycles = 8bits => adder must be 8-bits
  --                      RF1-RF2-S1-S2-RM-WM-S3-WF
  signal cw_mem : mem_array := (
                                "001000000000",
                                "000001000000",
                                "000000001001",
                                "000000000000",
                                "001000000000",
                                "000001000000",
                                "000000001001",
                                "000000000000",
                                "001000000000",
                                "000001000000",
                                "000000001001",
                                "000000000000",
                                "001000000000",
                                "000001000000",
                                "000000001001",
                                "000000000000",
                                "001000000000",
                                "000001000000",
                                "000000001001",
                                "000000000000",
                                "001000000000",
                                "000001000000",
                                "000000001001",
                                "000000000000",
                                "001000000000",
                                "000001000000",
                                "000000001001",
                                "000000000000",
                                "001000000000",
                                "000001000000",
                                "000000001001",
                                "000000000000",
                                "001000000000",
                                "000001000000",
                                "000000001001",
                                "000000000000",
                                "001000000000",
                                "000001000000",
                                "000000001001",
                                "000000000000",
                                "001000000000",
                                "000001000000",
                                "000000001001",
                                "000000000000",
                                "001000000000",
                                "000001000000",
                                "000000001001",
                                "000000000000",
                                "001000000000",
                                "000001000000",
                                "000000001001",
                                "000000000000",
                                "001000000000",
                                "000001000000",
                                "000000001001",
                                "000000000000",
                                "001000000000",
                                "000001000000",
                                "000000001001",
                                "000000000000",
                                "001000000000",
                                "000001000000",
                                "000000001001",
                                "000000000000",
                                "001000000000",
                                "000001000000",
                                "000000001001",
                                "000000000000",
                                "001000000000",
                                "000001000000",
                                "000000001001",
                                "000000000000",
                                "001000000000",
                                "000001000000",
                                "000000001001",
                                "000000000000",
                                "001000000000",
                                "000001000000",
                                "000000001001",
                                "000000000000",
                                "001000000000",
                                "000001000000",
                                "000000001001",
                                "000000000000",
                                "001000000000",
                                "000001000000",
                                "000000001001",
                                "000000000000",
                                "001000000000",
                                "000001000000",
                                "000000001001",
                                "000000000000",
                                "001000000000",
                                "000001000000",
                                "000000001001",
                                "000000000000",
                                "001000000000",
                                "000001000000",
                                "000000001001",
                                "000000000000",
                                "001000000000",
                                "000001000000",
                                "000000001001",
                                "000000000000",
                                "001000000000",
                                "000001000000",
                                "000000001001",
                                "000000000000",
                                "001000000000",
                                "000001000000",
                                "000000001001",
                                "000000000000",
                                "001000000000",
                                "000001000000",
                                "000000001001",
                                "000000000000",
                                "001000000000",
                                "000001000000",
                                "000000001001",
                                "000000000000",
                                "001000000000",
                                "000001000000",
                                "000000001001",
                                "000000000000",
                                "001000000000",
                                "000001000000",
                                "000000001001",
                                "000000000000",
                                "001000000000",
                                "000001000000",
                                "000000001001",
                                "000000000000",
                                "001000000000",
                                "000001000000",
                                "000000001001",
                                "000000000000",
                                "001000000000",
                                "000001000000",
                                "000000001001",
                                "000000000000",
                                "001000000000",
                                "000001000000",
                                "000000001001",
                                "000000000000",
                                "001000000000",
                                "000001000000",
                                "000000001001",
                                "000000000000",
                                "001000000000",
                                "000001000000",
                                "000000001001",
                                "000000000000",
                                "001000000000",
                                "000001000000",
                                "000000001001",
                                "000000000000",
                                "001000000000",
                                "000001000000",
                                "000000001001",
                                "000000000000",
                                "001000000000",
                                "000001000000",
                                "000000001001",
                                "000000000000",
                                "001000000000",
                                "000001000000",
                                "000000001001",
                                "000000000000",
                                "001000000000",
                                "000001000000",
                                "000000001001",
                                "000000000000",
                                "001000000000",
                                "000001000000",
                                "000000001001",
                                "000000000000",
                                "001000000000",
                                "000001000000",
                                "000000001001",
                                "000000000000",
                                "001000000000",
                                "000001000000",
                                "000000001001",
                                "000000000000",
                                "001000000000",
                                "000001000000",
                                "000000001001",
                                "000000000000",
                                "001000000000",
                                "000001000000",
                                "000000001001",
                                "000000000000",
                                "001000000000",
                                "000001000000",
                                "000000001001",
                                "000000000000",
                                "001000000000",
                                "000001000000",
                                "000000001001",
                                "000000000000",
                                "001000000000",
                                "000001000000",
                                "000000001001",
                                "000000000000",
                                "001000000000",
                                "000001000000",
                                "000000001001",
                                "000000000000",
                                "001000000000",
                                "000001000000",
                                "000000001001",
                                "000000000000",
                                "001000000000",
                                "000001000000",
                                "000000001001",
                                "000000000000",
                                "001000000000",
                                "000001000000",
                                "000000001001",
                                "000000000000",
                                "001000000000",
                                "000001000000",
                                "000000001001",
                                "000000000000",
                                "001000000000",
                                "000001000000",
                                "000000001001",
                                "000000000000",
                                "001000000000",
                                "000001000000",
                                "000000001001",
                                "000000000000",
                                "001000000000",
                                "000001000000",
                                "000000001001",
                                "000000000000",
                                "001000000000",
                                "000001000000",
                                "000000001001",
                                "000000000000",
                                "001000000000",
                                "000001000000",
                                "000000001001",
                                "000000000000",
                                "001000000000",
                                "000001000000",
                                "000000001001",
                                "000000000000",
                                "001000000000",
                                "000001000000",
                                "000000001001",
                                "000000000000",
                                "001000000000",
                                "000001000000",
                                "000000001001",
                                "000000000001" -- This is the address to which the process will jump when resetted (NOP and fetch)
                              );

  signal currentCode: CODE;
  signal currentFunc: FUNC;
  signal controlWord: std_logic_vector(CW_SIZE-1 downto 0);

  signal fetch, dontfetch: std_logic;
  signal plusone: std_logic_vector(7 downto 0);
  signal currentUPC: std_logic_vector(7 downto 0);
  signal opcode_extended: std_logic_vector(7  downto 0);
  signal opcode_extended_inited: std_logic_vector(7  downto 0);

  signal rst_sync: std_logic;
  
begin
  
  -- INIZIALIZATION OF THE MICROCODE
  -- WHEN RESET IS PUT TO 0, MICROCODE MEMORY WILL GO TO 0xFFFF.., WHICH CORRESPONDS TO A NOP w/FETCH
  rst_flipflop:  process(RST) begin
         rst_sync <= RST;
  end process;
  
  init_pc_mux: entity work.MUX21_GENERIC
  GENERIC MAP (
     WIDTH => ceil_log2(MICROCODE_MEM_SIZE)
    )
  PORT MAP( A => opcode_extended, B => (OTHERS => '1'), S => rst_sync, Y => opcode_extended_inited);
 
  plusone <= (0=> '1', OTHERS => '0');
  --Last 2 bits of the 8 of uPC are used to select the stage (00, 01, 10)
  -- In this way the 4 opcode bits are directly mapped to memory and a new fetch always starts at XXXXXX00
  dontfetch <= not controlWord(0);
  opcode_extended <= OPCODE & "00";
  upc_increment: ENTITY work.ACC(Structural)
  GENERIC MAP(WIDTH => 8) 
  PORT MAP(A => plusone, B=> opcode_extended_inited, CK => CLK, accumulate => dontfetch, acc_enable=> '0', Y => currentUPC, RESET => RST);

  fetch <= controlWord(0);
  --Gets latched opcode from accumulator
  currentCode <= currentUPC(2+OP_CODE_SIZE-1 DOWNTO 2);
  --Latches FUNC from the port
  func_latch: ENTITY work.REG_GENERIC
  GENERIC MAP(WIDTH => FUNC_SIZE)
  PORT MAP(D => FUNC_IN, CK => CLK, RESET => RST, Q => currentFunc);
  currentCode <= currentUPC(2+OP_CODE_SIZE-1 DOWNTO 2);

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

  controlWord <= cw_mem(to_integer(unsigned(currentUPC)));
  --Copypasted from port declaration
    RF1 <= controlWord(11);
    RF2 <= controlWord(10);
    
    EN1 <= controlWord(9);
           
    S1   <= controlWord(8);
    S2   <= controlWord(7);
    
    EN2  <= controlWord(6);
          
    RM   <= controlWord(5);
    WM   <= controlWord(4);

    EN3 <= controlWord(3);
    
    S3   <= controlWord(2);
    WF1 <= controlWord(1);


end CU_UP;
