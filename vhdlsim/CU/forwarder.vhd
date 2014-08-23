LIBRARY IEEE;
USE IEEE.std_logic_1164.ALL;
USE work.myTypes.ALL;
USE work.opcodes.ALL;

--This entity manages forwarding. 
--It takes a snapshot of the past 2 IRs going through the pipeline and follows this logic:
--source register A:
--The address of this register is put in bits 25~21.
--source register B: bits 20~16. This register is only present if there is a R-TYPE operation (000000) or a store, but can always be multiplexed - in the worst case it will not be used
--Destination register D: r2 (bits 20~16) or r3 (bits 15~11), depending on wether this is a R-TYPE (r3) or not (r2).
--Logic for both muxes ("current" means "entering the ALU"):
--If current source register S is equal to D1, take it (last operation writing on D1 is the previously current operation - register ALU_OUT) 
--Else if S is equal to D2, take it (last operation writing on D2 is the one which just exited the memory and has been writeback'd on the current clock edge - so it couldn't be read before.)
--Note that the critical case is a ALU operation needing a register which has just been read from memory, e.g.
--load R1
--add R2, R1, R3
--But this situation will never happen as the fetch stage will recognize it and change it to
--load R1
--nop
--add R2, R1, R3
--which can be correctly executed using the method above.

ENTITY FORWARDER IS
  PORT(
    CLK: in std_logic;
    RESET: in std_logic;
    IR: in INSTRUCTION;
    SELECT_RIGHTA: out std_logic_vector(1 downto 0);
    SELECT_RIGHTB: out std_logic_vector(1 downto 0)
  );
END FORWARDER;

ARCHITECTURE STRUCTURAL OF FORWARDER IS
  SIGNAL D2, D1, SA, SB, D: REG_ADDRESS;
  SIGNAL ir_is_rtype: std_logic;
  SIGNAL ir_is_notwriting, ir_was_notwriting, ir_was_notwriting2: std_logic;
BEGIN
  --Takes informations about the current instruction in order to execute it 
  ir_is_rtype <= '1' when opcodeof(IR)=OPCODE_RTYPE else '0';
  --If the instruction is a notwriting, the destination register has another purpose -> IGNORE IT!
  ir_is_notwriting <= '0' when does_not_write(opcodeof(IR)) else '1'; -- This value is active-low so that upon a reset the instructions will not be touched

  SA <= r1of(IR);
  SB <= r2of(IR);
  select_dest: ENTITY work.MUX21_GENERIC
  GENERIC MAP(WIDTH => REG_ADDRESS_SIZE) PORT MAP(A => r3of(IR), B => r2of(IR), S => ir_is_rtype, Y => D); -- Selects the destination of this operation

  previous_operation: ENTITY work.REG_GENERIC
  GENERIC MAP(WIDTH => REG_ADDRESS_SIZE) PORT MAP(D => D, CK => CLK, RESET => RESET, Q => D1);
  second_previous_operation: ENTITY work.REG_GENERIC
  GENERIC MAP(WIDTH => REG_ADDRESS_SIZE) PORT MAP(D => D1, CK => CLK, RESET => RESET, Q => D2);

  prev_was_a_notwriting: ENTITY work.REG_GENERIC
  GENERIC MAP(WIDTH => 1) PORT MAP(D(0) => ir_is_notwriting, CK => CLK, RESET => RESET, Q(0) => ir_was_notwriting);
  prev_was_a_notwriting2: ENTITY work.REG_GENERIC
  GENERIC MAP(WIDTH => 1) PORT MAP(D(0) => ir_was_notwriting, CK => CLK, RESET => RESET, Q(0) => ir_was_notwriting2);

  manage_signals: process(IR, SA, SB, D1, D2, ir_was_notwriting, ir_was_notwriting2) begin
    --Give precedence to ALU
    if(SA=D1 and ir_was_notwriting='1') then -- Remember that ir_was_notwriting* is active LOW (1=NOT notwriting)
      SELECT_RIGHTA <= "10";
    elsif(SA=D2 and ir_was_notwriting2='1') then
      SELECT_RIGHTA <= "11";
    else
      SELECT_RIGHTA <= "01"; -- Keeps the read register as the good one
    end if;

    --Same thing for mux B
    if(SB=D1 and ir_was_notwriting='1') then
      SELECT_RIGHTB <= "10";
    elsif(SB=D2 and ir_was_notwriting2='1') then
      SELECT_RIGHTB <= "11";
    else
      SELECT_RIGHTB <= "01"; -- Keeps the read register as the good one
    end if;
  end process;
END ARCHITECTURE;
