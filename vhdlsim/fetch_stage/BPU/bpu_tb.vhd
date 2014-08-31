LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE work.myTypes.all;
USE ieee.numeric_std.all;

ENTITY BPU_TB IS
END BPU_TB;

ARCHITECTURE bahbievfb OF BPU_TB IS
  signal pc: CODE_ADDRESS := (OTHERS => '0');
  signal clk: std_logic := '0';
  signal reset: std_logic := '0';
  signal opcode: CODE := (OTHERS => '0');
  signal branch_outcome, branch_outcome_1cycleafter, branch_outcome_2cyclesafter: std_logic;
  signal pred: std_logic;
  signal no_check: std_logic;
  signal force_wrong: std_logic;
  
  signal allzeroes: std_logic_vector(CODE_ADDRESS_SIZE-1 downto 0); --sets the proper result lengh hwhen performing addition to assign a value to PC

BEGIN

  clk <= not clk after 10 ns;

  zeroes: for i in 0 to CODE_ADDRESS_SIZE-1 generate
      allzeroes(i)<='0';
  end generate;


  pipeline_thingy:PROCESS(clk) --just to let you specify the future result of a branch AS SOON AS you ask for the prediction of that branch.
  begin
      if (clk='1' and clk'event) then
          branch_outcome_1cycleafter <= branch_outcome;
          branch_outcome_2cyclesafter <= branch_outcome_1cycleafter;
      end if;
  end process;


  PROCESS
  begin

      reset <= '0';
      wait for 20 ns;
      reset <= '1';  --fills the BHT's rows with the default values ("00" - Strong Not Taken).

      pc <= (others=>'0'); --the PC won't be used at first (prediction won't depend on it)
      branch_outcome <= '0';  --neither is this (at first).



      opcode <= "000010";  --unconditioned jmp => always output PRED='1',NO_CHECK='1'
      wait for 20*2 ns;

      opcode <= "010010";  --JR => FORCE_WRONG = '1'
      wait for 20*2 ns;


      --NOW the pc will actually be used (branches incoming):


      --after 2 clock cycles, this outcome will be picked up by the BPU and the internal state or row 0 of the BHT will start to change.
      --after one more clock cycle, the state will switch to "Weak Taken" and you'll see the prediction changing.

      pc <= std_logic_vector(unsigned(allzeroes)+0);
      opcode <= "000100";  --BEQZ => use BHT.
      branch_outcome <= '1'; --"taken" => this makes state go to "01"
      wait for 20*1 ns;


      pc <= std_logic_vector(unsigned(allzeroes)+0);
      opcode <= "000100";  --BEQZ
      branch_outcome <= '1';  --"taken" => this makes state go to "10" => PREDICTION SWITCHES from not taken to taken

      wait for 20*1 ns;


      pc <= std_logic_vector(unsigned(allzeroes)+0);
      opcode <= "000100";  --BEQZ
      branch_outcome <= '1';   --"taken" => this makes state go to "11"

      wait for 20*1 ns;


      --now change PC => prediction should restart from the default "00"

      pc <= std_logic_vector(unsigned(allzeroes)+1);
      opcode <= "000100";  --BEQZ => use BHT.
      branch_outcome <= '1'; --"taken" => this makes state go to "01"
      wait for 20*1 ns;


      pc <= std_logic_vector(unsigned(allzeroes)+1);
      opcode <= "000100";  --BEQZ
      branch_outcome <= '1';  --"taken" => this makes state go to "10"

      wait for 20*1 ns;


      pc <= std_logic_vector(unsigned(allzeroes)+1);
      opcode <= "000100";  --BEQZ
      branch_outcome <= '1';   --"taken" => this makes state go to "11"

      wait for 20*1 ns;

      --go back to previous PC/BHT row => prediction should resume from the state that it was left into last time ("11"):

      pc <= std_logic_vector(unsigned(allzeroes)+0);
      opcode <= "000100";  --BEQZ => use BHT.
      branch_outcome <= '0'; --"taken" => this makes state go down to "10"
      wait for 20*1 ns;


      pc <= std_logic_vector(unsigned(allzeroes)+0);
      opcode <= "000100";  --BEQZ
      branch_outcome <= '0';  --"taken" => this makes state go down to "01" => PREDICTION SWITCHES from taken to not taken

      wait for 20*1 ns;


      pc <= std_logic_vector(unsigned(allzeroes)+0);
      opcode <= "000100";  --BEQZ
      branch_outcome <= '0';   --"taken" => this makes state go to "00"

      wait for 20*1 ns;

      wait;

      --pc <= std_logic_vector(unsigned(pc)+1);


  wait;

  end process;

  bpu_totest: ENTITY work.BPU(structural_bht) PORT MAP(pc=>pc, clk=>clk, reset=>reset, opcode=>opcode, branch_outcome=>branch_outcome, pred=>pred, no_check=>no_check, force_wrong=>force_wrong);
END ARCHITECTURE;
