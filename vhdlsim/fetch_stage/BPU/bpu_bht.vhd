LIBRARY IEEE;
use IEEE.std_logic_1164.all;
use work.myTypes.all;

--needed to declare a signal compatible with the output of the demultiplexer
use WORK.DEMUX_GENERIC_OUTPUT.all;

use WORK.MUX_GENERIC_INPUT.all;

use WORK.ceillog.all;



ARCHITECTURE structural_bht OF work.BPU is

constant BHT_ROWS: integer := 1024; --size of the BHT = 2^k. since the IRAM is currently 1024 instructions, k=10 covers each instruction of the IRAM with a separate BHT row => no collisions can happen => best possible prediction accuracy.

signal time_to_update: std_logic;  --two cycles after any prediction, this signal will become '1':
                                   --it means that the BPU is ready to get back the actual branch outcome, and use it to update the corresponding line of the BHT.
                                   --(concretely, this signal is used to enable the BHT row to change the value in the state register)

signal which_row, which_row_1cyclelater, which_row_2cycleslater: std_logic_vector(ceil_log2(BHT_ROWS)-1 downto 0);
signal pred_requested, pred_requested_1cyclelater, pred_requested_2cycleslater: std_logic;

signal demux_input: std_logic_vector(1 downto 0);
signal demux_outputs: demux_generic_output(BHT_ROWS-1 downto 0, 1 downto 0);

signal bht_out: std_logic_vector(0 downto 0); --the BHT will output the currently selected prediction on this signal.

signal mux_inputs:  mux_generic_input(BHT_ROWS-1 downto 0, 0 downto 0);

BEGIN

  --Structural BPU based on a 2-bit BHT:


  -------------------------------------------------------------------------------------
  -- INPUT HALF of the BHT:                                                          --
  -- This gets activated 2 cycles after any prediction is requested (and supplied),  --
  -- to get back the actual branch outcome and use it to update the BHT row          --
  -- that was used to generate the prediction.                                       --
  -------------------------------------------------------------------------------------

  time_to_update <= pred_requested_2cycleslater; --if pred_requested was set to '1' two cycles ago, now pred_requested_2cycleslater is finally '1' too.
                                                 --and time_to_update is just hardwired to it, because the name is easier to remember.

  demux_input(0) <= BRANCH_OUTCOME;  --the actual branch outcome (1 bit), this comes from the outside (it's computed in fetch_stage, and supplied 2 cycles after any prediction).
  demux_input(1) <= time_to_update; --will turn to '1' two cycles after any branch prediction,
                                    --because that's when the actual branch result will come back to update the status register of the corresponding BHT row.
                                    --this will turn to '1' to enable the selected state register's EN input.

  which_row <= PC(ceil_log2(BHT_ROWS)-1 downto 0);  --take as input the first k bits of the Branch instruction's address in IRAM (which is the current value of the PC).


  demux0: entity work.DEMUX_GENERIC 
  GENERIC MAP(
      WIDTH => 2,  --width of input/outputs: a hardwired '1' that goes to the selected state register's EN input, and the actual branch outcome (1 bit).
      HEIGHT => BHT_ROWS
  )
  PORT MAP(
      A => demux_input, 
      S => which_row_2cycleslater,
      Y => demux_outputs
  );


  --------------------------------------------------------------------------------------
  -- ROWS of the BHT itself:                                                          --
  -- Here are the rows of the BHT: they're used to supply predictions when requested, --
  -- then they also get updated 2 cycles later using the actual branch result.        --
  --------------------------------------------------------------------------------------

  generate_rows: for i in 0 to BHT_ROWS-1 generate

      bht_row: entity work.BHT_ONEROW 
      PORT MAP(
          CLK => CLK,
          EN => demux_outputs(i, 1),
          RST => RESET,
          INPUT => demux_outputs(i, 0),
          OUTPUT => mux_inputs(i, 0)
      );

  end generate;

  -------------------------------------------------------------------------------------
  -- OUTPUT HALF of the BHT:                                                         --
  -- This gets activated whenever a prediction is requested,                         --
  -- to get back the actual branch outcome and use it to update the BHT row          --
  -- that was used to generate the prediction.                                       --
  -------------------------------------------------------------------------------------

  mux0: entity work.MUX_GENERIC 
  GENERIC MAP(
      WIDTH => 1,  --width of inputs/output: just one bit for the branch prediction.
      HEIGHT => BHT_ROWS  --has one input for each BHT row (each one outputs its most updated prediction, mux selects the appropriate one for current request).
  )
  PORT MAP(
      A => mux_inputs,  --TODO: i'm VERY afraid that i'll have to map a DEMUX_GENERIC_OUTPUT signal to a MUX_GENERIC_INPUT of the same size just to make it get into the multiplexer, despite them begin defined in the same exact way.
      S => which_row,
      Y => bht_out
  );

  --PRED <= bht_out(0); --NO, not directly. the bht_out signal whould be left as just the output of the mux, and THEN the process below will decide whether to take PRED from this signal, or just send '0' or '1' as PRED's value.



  process(CLK) --pipelining of the which_row and pred_requested signals,
               --to make them get into the demux's input ports (respectively S and A(1)) TWO CYCLES AFTER they got into the mux's corresponding inputs.
  begin
      which_row_2cycleslater <= which_row_1cyclelater;
      which_row_1cyclelater  <= which_row;

      pred_requested_2cycleslater <= pred_requested_1cyclelater;
      pred_requested_1cyclelater  <= pred_requested;
  end process;

  --If we have an unconditioned JMP, we must predict a 1, otherwise go look at the corresponding BHT line.
  --New value is attached from the external
  --NOTE: Opcode changes synchronously, because it's managed outside of this block by the fetch_unit.
  process(OPCODE)
  begin
    pred_requested <= '0';    --default assignment of prediction_requested;
    case OPCODE is
      when "000010" | "000011" =>
        --Unconditioned jmp
        PRED<='1';
        NO_CHECK <= '1';
        FORCE_WRONG <= '0';

      when "000100" | "000101" => 
        --Conditioned (BEQZ or BNEZ, respectively) - HERE we employ the BHT.
        PRED<=bht_out(0);
        NO_CHECK <= '0';
        FORCE_WRONG <= '0';
        pred_requested <= '1';   --in THIS case, warn the BHT that a prediction was taken out of its table (this "warning" will get to the BHT 2 cycles later, when it's time to update the BHT's content.)

      when "010010" | "010011" => 
        --Predict WRONG (jr)
        PRED<='0';
        NO_CHECK <= '0';
        FORCE_WRONG <= '1';
      when OTHERS =>
        --EVERY other case (=not a jump/branch instruction) => prediction not necessary => set NO_CHECK to '1'.
        PRED <= '0';
        NO_CHECK <= '1';
        FORCE_WRONG <= '0';
    end case;
  end process;
END;
