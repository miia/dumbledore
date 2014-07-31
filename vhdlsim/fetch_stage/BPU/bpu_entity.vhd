LIBRARY IEEE;
use IEEE.std_logic_1164.ALL;
use work.myTypes.ALL;

ENTITY BPU is
PORT(
  PC: in CODE_ADDRESS_STRETCHED;
  CLK: in std_logic;
  OPCODE: in CODE; -- incoming opcode of the instruction 
  NO_CHECK: out std_logic;
  PRED: out std_logic
);
END BPU;

