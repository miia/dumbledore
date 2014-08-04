library ieee;
use ieee.std_logic_1164.all;
use work.myTypes.all;

package opcodes is
  constant OPCODE_RTYPE: CODE := "000000";
  constant OPCODE_ADD: CODE := "000000";
  constant OPCODE_SUB: CODE := "000000";
  constant OPCODE_ADDI: CODE := "000000";
  constant OPCODE_SUBI: CODE := "000000";
  constant OPCODE_LB: CODE := "100000";
  constant OPCODE_LH: CODE := "100001";
  constant OPCODE_LW: CODE := "100011";
  constant OPCODE_LBU: CODE := "100100";
  constant OPCODE_LHU: CODE := "100101";
  constant OPCODE_NOP: CODE := "010101";
end package;

