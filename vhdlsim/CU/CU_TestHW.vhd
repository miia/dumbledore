library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_unsigned.all;
use ieee.std_logic_arith.all;
use work.myTypes.all;

entity cu_testhw is
end cu_testhw;

architecture TESTHW of cu_testhw is

    signal Clock: std_logic := '0';
    signal Reset: std_logic := '1';

    signal cu_opcode_i: std_logic_vector(OP_CODE_SIZE - 1 downto 0) := (others => '0');
    signal cu_func_i: std_logic_vector(FUNC_SIZE - 1 downto 0) := (others => '0');
    signal EN1_i, RF1_i, RF2_i, WF1_i, EN2_i, S1_i, S2_i, EN3_i, RM_i, WM_i, S3_i: std_logic := '0';
    signal ALU: std_logic_vector(8 downto 0);

    constant n: integer := 1; --how many clock cycles between two consecutive instructions entering the CU?

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
                 PRED   => '0',          
                 Clk    => Clock,
                 Rst    => Reset
               );

        Clock <= not Clock after 1 ns;
	Reset <= '0', '1' after 6 ns; --hold reset active for first 6 ns


        CONTROL: process
        begin

        wait for 6 ns;  ----- be careful! the wait statement is ok in test
                        ----- benches, but do not use it in normal processes!

        --R-TYPE INSTRUCTIONS:

        -- ADD RS1,RS2,RD -> Rtype
        cu_opcode_i <= CODE_RTYPE_ADD;
        cu_func_i <= FUNC_ADD;
        wait for n*2 ns; --2ns = clock period; n*2 ns = n clock periods.

        -- SUB RS1,RS2,RD -> Rtype
        cu_opcode_i <= CODE_RTYPE_SUB;
        cu_func_i <= FUNC_SUB;
        wait for n*2 ns; --2ns = clock period; n*2 ns = n clock periods.

        -- AND RS1,RS2,RD -> Rtype
        cu_opcode_i <= CODE_RTYPE_AND;
        cu_func_i <= FUNC_AND;
        wait for n*2 ns; --2ns = clock period; n*2 ns = n clock periods.

        -- OR RS1,RS2,RD -> Rtype
        cu_opcode_i <= CODE_RTYPE_OR;
        cu_func_i <= FUNC_OR;
        wait for n*2 ns; --2ns = clock period; n*2 ns = n clock periods.

	--I-TYPE INSTRUCTIONS:

        -- ADDI1 RS1,RD,INP1 -> Itype
        cu_opcode_i <= CODE_ITYPE_ADD1;
        cu_func_i <= (OTHERS => '0');
        wait for n*2 ns;

        -- SUBI1 RS1,RD,INP1 -> Itype
        cu_opcode_i <= CODE_ITYPE_SUB1;
        cu_func_i <= (OTHERS => '0');
        wait for n*2 ns;

        -- ANDI1 RS1,RD,INP1 -> Itype
        cu_opcode_i <= CODE_ITYPE_AND1;
        cu_func_i <= (OTHERS => '0');
        wait for n*2 ns;

	-- ORI1 RS1,RD,INP1 -> Itype
	cu_opcode_i <= CODE_ITYPE_OR1;
	cu_func_i <= (OTHERS => '0');
	wait for n*2 ns;

        -- ADDI2 RS1,RD,INP1 -> Itype
        cu_opcode_i <= CODE_ITYPE_ADD2;
        cu_func_i <= (OTHERS => '0');
        wait for n*2 ns;

        -- SUBI2 RS1,RD,INP1 -> Itype
        cu_opcode_i <= CODE_ITYPE_SUB2;
        cu_func_i <= (OTHERS => '0');
        wait for n*2 ns;

        -- ANDI2 RS1,RD,INP1 -> Itype
        cu_opcode_i <= CODE_ITYPE_AND2;
        cu_func_i <= (OTHERS => '0');
        wait for n*2 ns;

	-- ORI2 RS1,RD,INP1 -> Itype
	cu_opcode_i <= CODE_ITYPE_OR2;
	cu_func_i <= (OTHERS => '0');
	wait for n*2 ns;

	-- MOV R1, R2 -> Itype
	cu_opcode_i <= CODE_ITYPE_MOV;
	cu_func_i <= (OTHERS => '0');
	wait for n*2 ns;

	-- S_REG1 R2, INP1 -> Itype
	cu_opcode_i <= CODE_ITYPE_SREG1;
	cu_func_i <= (OTHERS => '0');
	wait for n*2 ns;

	-- S_REG2 R2, INP2 -> Itype
	cu_opcode_i <= CODE_ITYPE_SREG2;
	cu_func_i <= (OTHERS => '0');
	wait for n*2 ns;

	-- S_MEM2 R1, R2, INP2 -> Itype
	cu_opcode_i <= CODE_ITYPE_SMEM2;
	cu_func_i <= (OTHERS => '0');
	wait for n*2 ns;

	-- L_MEM1 R1, R2, INP1 -> Itype
	cu_opcode_i <= CODE_ITYPE_LMEM1;
	cu_func_i <= (OTHERS => '0');
	wait for n*2 ns;

	-- L_MEM2 R1, R2, INP2 -> Itype
	cu_opcode_i <= CODE_ITYPE_LMEM2;
	cu_func_i <= (OTHERS => '0');
	wait for n*2 ns;


        wait;
        end process;

end TESTHW;
