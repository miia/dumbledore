library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use work.myTypes.all;

entity cu_test is
end cu_test;

architecture TEST of cu_test is

    signal Clock: std_logic := '0';
    signal Reset: std_logic := '1';

    signal cu_opcode_i: std_logic_vector(OP_CODE_SIZE - 1 downto 0) := (others => '0');
    signal cu_func_i: std_logic_vector(FUNC_SIZE - 1 downto 0) := (others => '0');
    signal EN1_i, RF1_i, RF2_i, WF1_i, EN2_i, S1_i, S2_i, EN3_i, RM_i, WM_i, S3_i: std_logic := '0';
    signal ALU: std_logic_vector(1 downto 0);

begin

        -- instance of DLX
       dut: ENTITY work.dlx_cu(CU_HW)
       port map (
                 -- OUTPUTS
                 EN1    => EN1_i,
                 RF1    => RF1_i,
                 RF2    => RF2_i,
                 WF1    => WF1_i,
                 EN2    => EN2_i,
                 S1     => S1_i,
                 S2     => S2_i,
                 ALU   => ALU,
                 EN3    => EN3_i,
                 RM     => RM_i,
                 WM     => WM_i,
                 S3     => S3_i,
                 -- INPUTS
                 OPCODE => cu_opcode_i,
                 FUNC_IN   => cu_func_i,            
                 Clk    => Clock,
                 Rst    => Reset
               );

        Clock <= not Clock after 1 ns;
	     Reset <= '0', '1' after 6 ns;


        CONTROL: process
        begin

        wait for 6 ns;  ----- be careful! the wait statement is ok in test
                        ----- benches, but do not use it in normal processes!

        -- ADD RS1,RS2,RD -> Rtype
        cu_opcode_i <= CODE_RTYPE_ADD;
        cu_func_i <= FUNC_ADD;
        wait for 3 ns;

        -- ADDI1 RS1,RD,INP1 -> Itype
        cu_opcode_i <= CODE_ITYPE_AND1;
        cu_func_i <= (OTHERS => '0');
        wait for 3 ns;
-- ADDI1 RS1,RD,INP1 -> Itype
cu_opcode_i <= CODE_ITYPE_SUB1;
cu_func_i <= (OTHERS => '0');
wait for 3 ns;
        -- .............
        -- add all the others instructions
        -- .............

        wait;
        end process;

end TEST;
