LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE work.myTypes.all;
USE work.opcodes.all;

ENTITY TB_FETCH_STAGE IS
END TB_FETCH_STAGE;

ARCHITECTURE tb OF TB_FETCH_STAGE IS
    SIGNAL CLK:  std_logic := '0';
    SIGNAL RESET:  std_logic := '0';
    
    --Signals for code memory
    SIGNAL RDMEM:  std_logic;
    SIGNAL RDADDR:  std_logic_vector(33 downto 0);
    SIGNAL INST, FETCHED_INST:  INSTRUCTION;
    SIGNAL NOT_JMP_TAKEN:  std_logic; -- This one goes to the CU, which will decide how to compute the new address  case of wrong prediction ( this case, it will send to the ALU the fallback components of the fallback address
    -- Not needed anymore? I'm merge BPU *and* related registers **and* checks of right/wrong prediction *to* fetch stage PC:  CODE_ADDRESS
    SIGNAL FLUSH_PIPELINE:  std_logic; -- As before, this is needed for the merge; could be smart

--Get the current status of flags 
    SIGNAL THE_REGISTER: REGISTER_CONTENT;

  -- What to replace the PC with  case of wrong prediction
    SIGNAL FALLBACK_ADDRESS:  CODE_ADDRESS;
    SIGNAL DRIVEN_INST : CODE;
    
BEGIN
  toTest: ENTITY work.FETCH_STAGE
  PORT MAP (
  CLK => CLK,
  RESET => RESET,
  RDMEM => RDMEM,
  RDADDR => RDADDR,
  INST => INST,
  NOT_JMP_TAKEN => NOT_JMP_TAKEN,
  FLUSH_PIPELINE => FLUSH_PIPELINE,
  CHECK_REGISTER => THE_REGISTER,
  FALLBACK_ADDRESS => FALLBACK_ADDRESS,
  FETCHED_INST => FETCHED_INST
  );

  CLK <= not CLK after 10 ns;
  FALLBACK_ADDRESS <= (OTHERS => '1');
  
  INST(IR_SIZE-1 downto IR_SIZE-OP_CODE_SIZE) <= DRIVEN_INST;
  PROCESS BEGIN
    THE_REGISTER <= (OTHERS => '0'); -- Zero flag is active
      
    INST(IR_SIZE-OP_CODE_SIZE-1 downto 0) <= (4 => '1', OTHERS => '0'); -- Relative jmps are of +32
    --phase shift on the clock -- Memory gives data some time after the address (and thus the clock)
    wait for 15 ns;
    wait for 20 ns;
    RESET <= '1';

    --We put some add first..
    DRIVEN_INST <= OPCODE_ADD  ;

    wait for 60 ns;

    --Wooow, a jmp!
    DRIVEN_INST <= OPCODE_J;
    --Jmp propagates and real address will be computed..
    wait for 20 ns;
    DRIVEN_INST <= OPCODE_ADD;
    wait for 80 ns;

    --Jz - taken
    DRIVEN_INST <= "000100";
    wait for 20 ns;
    DRIVEN_INST <= OPCODE_ADD;
    wait for 80 ns;
    DRIVEN_INST <= "000101";
    wait for 20 ns;
    DRIVEN_INST <= OPCODE_LH;
    INST(IR_SIZE-OP_CODE_SIZE-1 downto 0) <= "00001000010000000000000000"; -- MOV R1, [R1]
    wait for 20 ns;
    DRIVEN_INST <= CODE_ITYPE_ADD1; -- ADD R1, R1, 0;
    wait for 20 ns;
    DRIVEN_INST <= CODE_ITYPE_ADD1; -- ADD R1, R1, 0;
    THE_REGISTER <= not THE_REGISTER;
    wait for 20 ns;

  END PROCESS;
END ARCHITECTURE;
