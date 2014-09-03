LIBRARY IEEE;
use IEEE.std_logic_1164.all;
use work.myTypes.all;

ARCHITECTURE structural_taken OF work.BPU is
BEGIN
  --If we have an unconditioned JMP, we must predict a 1, otherwise 0
  --New value is attached from the external
  process(OPCODE)
  begin
    case OPCODE is
      when "000010" | "000011" =>
        --Unconditioned jmp
        PRED<='1';
        NO_CHECK <= '1';
        FORCE_WRONG <= '0';
      when "000100" | "000101" => 
        --Conditioned jr
        PRED<='1';
        NO_CHECK <= '0';
        FORCE_WRONG <= '0';
      when "010010" | "010011" => 
        --Predict WRONG (jr)
        PRED<='0';
        NO_CHECK <= '0';
        FORCE_WRONG <= '1';
      when OTHERS =>
        PRED<='0';
        NO_CHECK <= '1';
        FORCE_WRONG <= '0';
    end case;
  end process;
END;
