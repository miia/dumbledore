--Booth's algorithm-based multiplier.
--As our adder supports carry in, in order to generate the -A/-2A inputs for the adder negated A/2A are passed as an input for the mux, and then +1 is added as needed as a carry in (so, also for the first block an adder is needed, but this is necessary as -A/-2A would have to be computed anyway.)
library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;
use work.mux_generic_input.all;

entity BOOTHMUL is
  GENERIC(
  WIDTH: natural -- Must be a multiple of 2
  );
  PORT(
    A: in std_logic_vector(WIDTH-1 downto 0);
    B: in std_logic_vector(WIDTH-1 downto 0);
    OUTPUT: out std_logic_vector(2*WIDTH-1 downto 0)
  );
end BOOTHMUL;

architecture structural of BOOTHMUL is

  signal B_extended, A_extended: std_logic_vector(WIDTH downto 0); -- B factor with bit -1 set to 0

  --Multiplexers
  TYPE   mux_ins is ARRAY(WIDTH/2-1 downto 0) of std_logic_vector(2 downto 0);
  signal input_selects: mux_ins;
  TYPE mux_out is array(WIDTH/2-1 downto 0) of std_logic_vector((WIDTH+2)-1 downto 0);
  signal mux_outputs: mux_out;
  
  TYPE partial_sum is array(WIDTH/2-1 downto 0)  of std_logic_vector((WIDTH+2)-1 downto 0);
  signal partials: partial_sum;
  
  -- First version: WIDTH+2 bits are necessary: WIDTH+1 are sufficient in most of the cases, but the worst case is whene last negative is associated to -2A (e.g. 4 bit -> (-2)*(-8)=16, which requires 6 bits
  --Actual version: WIDTH+2 bits are necessary: WIDTH+1 to store A/2A/not(A)/not(2A), last one to store sign which will go into carry in
  signal mux_in: mux_generic_input(4 downto 0, WIDTH+2-1 downto 0);
  type mux_in_array_t is ARRAY(4 downto 0) of std_logic_vector(WIDTH+2-1 downto 0);
  signal mux_in_array: mux_in_array_t;

  TYPE sum_inputs is ARRAY(WIDTH/2-1 downto 0) of std_logic_vector((WIDTH+2)-1 downto 0);
  signal sum_input_r: sum_inputs;
  signal sum_input_l: sum_inputs;

begin

  B_extended(0)<='0';
  B_extended(WIDTH downto 1) <= B;

  A_extended(WIDTH-1 downto 0) <= A;
  A_extended(WIDTH) <=  A(WIDTH-1);
  
  -- Each mux will have A, not A, 2A, not (2A) plus sign which will go to cin to provide A, -A, 2A, -2A
  -- Notice that sign extension is done through a mux
  mux_in_array(0)((WIDTH+2)-1 downto 0) <= (OTHERS => '0'); -- 0
  mux_in_array(1)((WIDTH+2)-1 downto 0) <=  '0' & A_extended; -- 2^i*A - extend sign on higher bit of A, put sign for A/-A
  mux_in_array(2)((WIDTH+2)-1 downto 0) <= '1' & (not A_extended); -- -(2^i*A)
  mux_in_array(3)((WIDTH+2)-1 downto 0) <= '0' & A & '0'; -- (2^(i+1)*A) (higher bit is removed),
  mux_in_array(4)((WIDTH+2)-1 downto 0) <= '1' & (not A) & '1'; -- -(2^(i+1)*A) (higher bit is removed),

  assign_values_to_muxinput: for i in 0 to 4 generate
    assign_inner: for j in 0 to WIDTH+2-1 generate
      mux_in(i,j)<=mux_in_array(i)(j);
    end generate;
  end generate;

  --NOTE on this structure: a shifted number has 0 at the end EVEN if with a minus sign!
  -- => final 0s can be safely ignored
  -- e.g. 16 (i.e. 1 shifted by 4) => 00010000, -16 => 11100000 (i.e. 2's complement of 1 shifted by 4)
  each_block: for i in 0 to WIDTH/2-1 generate
    encoder: ENTITY work.BOOTH_ENCODER
    PORT MAP(B_extended(i*2), B_extended(i*2+1), B_extended(i*2+2), input_selects(i));
   
    A_selector: ENTITY work.MUX_GENERIC
    GENERIC MAP(
      WIDTH => WIDTH+2,
      HEIGHT => 5
    )
    PORT MAP(
      A => mux_in,
      S => input_selects(i),
      Y  => mux_outputs(i)
    );

    -- Sum with previous term, last 2 bits go to result 
    OUTPUT(i*2+1 downto i*2)<=partials(i)(1 downto 0); -- Last 2 LSB of each block can be safely connected to output

    input_first_sign: if(not (i=0)) generate
      sum_input_r(i)(WIDTH-1 downto 0) <= partials(i-1)((WIDTH+2)-1 downto 2); -- Re-extend higher bits, as lower bits have already been removed
      sum_input_r(i)(WIDTH) <= partials(i-1)((WIDTH+2)-1);  -- As usual, extend sign if needed
      sum_input_r(i)(WIDTH+1) <= partials(i-1)((WIDTH+2)-1);    
    end generate;
    input_other_sign: if(i=0) generate
      sum_input_r(i) <= (OTHERS => '0');
    end generate;
    sum_input_l(i)((WIDTH+1)-1 downto 0) <=mux_outputs(i)((WIDTH+1)-1 downto 0); -- This mux with previous one, from which 2 bits have been already removed
    sum_input_l(i)(WIDTH+1) <= mux_outputs(i)((WIDTH+1)-1);

    adder: ENTITY work.P4_ADDER
      GENERIC MAP(
        WIDTH => WIDTH+2
      )
      PORT MAP(
        A => sum_input_l(i),
        B => sum_input_r(i),
        S => partials(i), -- Put sum in everything but last bit
        Cin => mux_outputs(i)((WIDTH+2)-1), -- sign
        Cout => open -- Sum is already extended
      );
  end generate;
  --MSB of last sum block can be connected to output too
  OUTPUT(WIDTH*2-1 downto WIDTH) <= partials(WIDTH/2-1)((WIDTH+2)-1 downto 2);
end architecture;
