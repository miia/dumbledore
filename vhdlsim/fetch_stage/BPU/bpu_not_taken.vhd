LIBRARY IEEE;
use IEEE.std_logic_1164.all;
use work.myTypes.all;

ARCHITECTURE structural_nottaken OF work.BPU is
BEGIN
  --If we have an unconditioned JMP, we must predict a 1, otherwise 0
  --New value is attached from the external
  process(OPCODE)
  begin
    case OPCODE(OP_CODE_SIZE-1 downto OP_CODE_SIZE-4) is
      when "0000" =>
        --Unconditioned jmp
        PRED<='1';
        NO_CHECK <= '1';
      when "0001" => 
        --Conditioned jr
        PRED<='0';
        NO_CHECK <= '0';
      when "0100" => 
        --Predict WRONG (jr)
        PRED<='0';
        NO_CHECK <= '1';
      when OTHERS =>
        PRED<='0';
        NO_CHECK <= '1';
    end case;
  end process;
END;
