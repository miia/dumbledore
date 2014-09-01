LIBRARY IEEE;
use IEEE.std_logic_1164.ALL;
use work.myTypes.ALL;

ENTITY BPU is
PORT(
  PC: in CODE_ADDRESS;
  CLK: in std_logic;
  RESET: in std_logic;
  OPCODE: in CODE; -- incoming opcode of the instruction
  BRANCH_OUTCOME: in std_logic;  --actual result corresponding to the last prediction that was computed (comes 2 cycles after the prediction took place; needed to update the belief of the BPU for next predictions) 
  NO_CHECK: out std_logic;
  PRED: out std_logic;
  FORCE_WRONG: out std_logic
);
END BPU;

