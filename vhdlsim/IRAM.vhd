library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use std.textio.all;
use ieee.std_logic_textio.all;

use work.myTypes.all;
use work.ceillog.all;

-- Instruction memory for DLX
-- Memory filled by a process which reads from a file
-- file name is "test.asm.mem"
entity IRAM is
  generic (
    RAM_DEPTH : integer := 48;
    I_SIZE : integer := 32);
  port (
    Rst  : in  std_logic;
    Addr : in  std_logic_vector(ceil_log2(RAM_DEPTH)-1 downto 0);
    Dout : out std_logic_vector(I_SIZE - 1 downto 0)
    );

end IRAM;

architecture IRam_Beh of IRAM is

  type RAMtype is array (0 to RAM_DEPTH - 1) of integer;-- std_logic_vector(I_SIZE - 1 downto 0);

  constant addr_top : integer := ceil_log2(RAM_DEPTH)-1;
  signal IRAM_mem : RAMtype;

begin  -- IRam_Bhe

  Dout <= conv_std_logic_vector(IRAM_mem(conv_integer(unsigned(Addr(addr_top downto 2)))),I_SIZE) after 1 ns;

  -- Process body executes every time reset goes low (resets are active-low here)
  -- it reads from a file containing machine code ("test.asm.mem") and fills IRAM_mem with instructions.
  FILL_MEM_P: process (Rst) -- asynchronous reset
    file mem_fp: text;
    variable file_line : line;
    variable index : integer := 0;
    variable tmp_data_u : std_logic_vector(I_SIZE-1 downto 0);
  begin  -- process FILL_MEM_P
    if (Rst = '0') then
      file_open(mem_fp,"software/test.asm.mem",READ_MODE);
      while (not endfile(mem_fp)) loop
        readline(mem_fp,file_line);
        hread(file_line,tmp_data_u);
        IRAM_mem(index) <= conv_integer(unsigned(tmp_data_u));       
        index := index + 1;
      end loop;
    end if;
  end process FILL_MEM_P;

end IRam_Beh;
