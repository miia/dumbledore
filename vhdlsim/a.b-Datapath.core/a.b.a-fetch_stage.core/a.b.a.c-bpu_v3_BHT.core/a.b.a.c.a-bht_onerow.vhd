LIBRARY IEEE;
use IEEE.std_logic_1164.all;
use work.myTypes.all;

--A single row of the 2-bits BHT;
--each row is implemented as a tiny Finite State Machine with a 1-bit output (taken/not taken) and four states, encoded as binary numbers:
--00 = strong not taken,
--01 = weak not taken,
--10 = weak taken,
--11 = strong taken.

ENTITY bht_onerow is
PORT(
  CLK:    in std_logic; --state changes on rising edge of clock signal
  EN:     in std_logic; --state is allowed to change (state register gets updated) ONLY IF this signal is high
  RST:    in std_logic;
  INPUT:  in std_logic;
  OUTPUT: out std_logic
);
END bht_onerow;

ARCHITECTURE structural OF work.bht_onerow is

signal A: std_logic; --mapped to FSM input
signal B: std_logic; --mapped to bit 1 of CURRENT state (output of state register, which feeds back into the combinational logic).
signal C: std_logic; --mapped to bit 0 of CURRENT state (output of state register, which feeds back into the combinational logic).
signal current_state: std_logic_vector(1 downto 0); --current state of the FSM: this signal implements the state register.
signal new_state: std_logic_vector(1 downto 0); --new state of the FSM: gets out of the combinational block, and goes to the input of the state register.


BEGIN

    A <= INPUT;
    B <= current_state(1);
    C <= current_state(0);

    --Purely combinational block, computes next state (an output, hardwired to bit 1 of next state)
    comb_logic: process(A,B,C)
    begin

        new_state(1) <= (A and B) or ((A or B) and C);
        new_state(0) <= (A and B) or ((A or B) and (not C));

    end process;

    --State register: this could be substituted by a 2-bits register.
    state_register: process(clk, rst)
    begin

        if RST='0' then -- active low reset 
            current_state <= "00"; --return to "Strong Not Taken" state
        else

            if (EN='1') then --NOTE: only update state to a new value if this line of the BHT is currently selected and receiving a new branch outcome... else, the values coming from the combinational block are ignored because they're just garbage.
                if (clk='1' and clk'event) then
                    current_state <= new_state;
                end if;
            end if;

        end if;

    end process;

    OUTPUT <= new_state(1);

END;
