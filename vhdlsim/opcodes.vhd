library ieee;
use ieee.std_logic_1164.all;
use work.myTypes.all;
use work.opcodes.all;

package opcodes is
  constant OPCODE_RTYPE: CODE := "000000";
  constant OPCODE_ADD: CODE := "000000";
  constant OPCODE_SUB: CODE := "000000";
  constant OPCODE_ADDI: CODE := "000000";
  constant OPCODE_SUBI: CODE := "000000";
  constant OPCODE_J: CODE := "000010";
  constant OPCODE_JAL: CODE := "000011";
  constant OPCODE_JALR: CODE := "010011";
  constant OPCODE_NOP: CODE := "010101";
  constant OPCODE_LB: CODE := "100000";
  constant OPCODE_LH: CODE := "100001";
  constant OPCODE_LW: CODE := "100011";
  constant OPCODE_LBU: CODE := "100100";
  constant OPCODE_LHU: CODE := "100101";
  constant OPCODE_SB: CODE := "101000";
  constant OPCODE_SH: CODE := "101001";
  constant OPCODE_SW: CODE := "101011";
  constant OPCODE_SF: CODE := "101110";
  constant OPCODE_SD: CODE := "101111";

  --Returns true if the opcode is an instruction that does not write to any register, i.e. a j, branch or store or nop
  --In particular, opcode can be 000xxx (j, b -with the exception of 000000); 101xxx (store), 010101 (nop), 01001x(jal)
  function does_not_write(opcode: CODE) return boolean;
end package;

package body opcodes is
  function does_not_write(opcode: CODE) return boolean is
  begin
    if(OPCODE(5 downto 3)="101" or (OPCODE(5 downto 3)="000" and OPCODE/=OPCODE_JAL and OPCODE/="000000") or OPCODE=OPCODE_NOP or OPCODE(5 downto 1)="01001") then
      return true;
    else
      return false;
    end if;
  end function;
end opcodes;


