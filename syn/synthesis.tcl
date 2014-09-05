
#1) Get all your non-testbench .vhd files with "find . -name "*.vhd" -not -name "tb*" | sort" !
# NOTE: don't include the IRAM - it shouldn't be synthesized.
set vhdfiles {
./vhdl/000-globals.vhd
./vhdl/000-opcodes.vhd
./vhdl/01-ceillog.vhd
./vhdl/01-log2.vhd
./vhdl/01-txt_util.vhd
./vhdl/02-fa.vhd
./vhdl/02-imm_extender.vhd
./vhdl/02-iv.vhd
./vhdl/02-latch.vhd
./vhdl/02-mux21_generic.vhd
./vhdl/02-mux21.vhd
./vhdl/02-mux_generic.vhd
./vhdl/02-nd2.vhd
./vhdl/02-reg_generic_enabled.vhd
./vhdl/02-reg_generic.vhd
./vhdl/03-delay_block.vhd
./vhdl/03-rca.vhd
./vhdl/04-ACC.vhd
./vhdl/a.a-CU_HW.core/forwarder.vhd
./vhdl/a.a-CU_HW.vhd
./vhdl/a.b-Datapath.core/a.b.a-fetch_stage.core/a.b.a.a-PC_ACC.vhd
./vhdl/a.b-Datapath.core/a.b.a-fetch_stage.core/a.b.a.b-bpu_entity.vhd
./vhdl/a.b-Datapath.core/a.b.a-fetch_stage.core/a.b.a.c-bpu_v1_not_taken.vhd
./vhdl/a.b-Datapath.core/a.b.a-fetch_stage.core/a.b.a.c-bpu_v2_taken.vhd
./vhdl/a.b-Datapath.core/a.b.a-fetch_stage.core/a.b.a.c-bpu_v3_BHT.core/a.b.a.c.a-bht_onerow.vhd
./vhdl/a.b-Datapath.core/a.b.a-fetch_stage.core/a.b.a.c-bpu_v3_BHT.core/a.b.a.c.b-demux_generic.vhd
./vhdl/a.b-Datapath.core/a.b.a-fetch_stage.core/a.b.a.c-bpu_v3_BHT.vhd
./vhdl/a.b-Datapath.core/a.b.a-fetch_stage.vhd
./vhdl/a.b-Datapath.core/a.b.b-registerfile.vhd
./vhdl/a.b-Datapath.core/a.b.c-ALU.core/a.b.c.a-arithmetic_unit.core/a.b.c.a.a-p4_adder.core/a.b.c.a.a.a-ha.vhd
./vhdl/a.b-Datapath.core/a.b.c-ALU.core/a.b.c.a-arithmetic_unit.core/a.b.c.a.a-p4_adder.core/a.b.c.a.a.b-pg.vhd
./vhdl/a.b-Datapath.core/a.b.c-ALU.core/a.b.c.a-arithmetic_unit.core/a.b.c.a.a-p4_adder.core/a.b.c.a.a.c-pg_network.vhd
./vhdl/a.b-Datapath.core/a.b.c-ALU.core/a.b.c.a-arithmetic_unit.core/a.b.c.a.a-p4_adder.core/a.b.c.a.a.d-generator.vhd
./vhdl/a.b-Datapath.core/a.b.c-ALU.core/a.b.c.a-arithmetic_unit.core/a.b.c.a.a-p4_adder.core/a.b.c.a.a.e-carryselect_block.vhd
./vhdl/a.b-Datapath.core/a.b.c-ALU.core/a.b.c.a-arithmetic_unit.core/a.b.c.a.a-p4_adder.core/a.b.c.a.a.f-carryselect_row.vhd
./vhdl/a.b-Datapath.core/a.b.c-ALU.core/a.b.c.a-arithmetic_unit.core/a.b.c.a.a-p4_adder.core/a.b.c.a.a.g-carry_generator.vhd
./vhdl/a.b-Datapath.core/a.b.c-ALU.core/a.b.c.a-arithmetic_unit.core/a.b.c.a.a-p4_adder.vhd
./vhdl/a.b-Datapath.core/a.b.c-ALU.core/a.b.c.a-arithmetic_unit.core/a.b.c.a.b-boothmul.core/a.b.c.a.b.a-booth_encoder.vhd
./vhdl/a.b-Datapath.core/a.b.c-ALU.core/a.b.c.a-arithmetic_unit.core/a.b.c.a.b-boothmul.vhd
./vhdl/a.b-Datapath.core/a.b.c-ALU.core/a.b.c.a-arithmetic_unit.vhd
./vhdl/a.b-Datapath.core/a.b.c-ALU.core/a.b.c.b-logic_unit.vhd
./vhdl/a.b-Datapath.core/a.b.c-ALU.core/a.b.c.c-shifter_generic.vhd
./vhdl/a.b-Datapath.core/a.b.c-ALU.core/a.b.c.d-comparator_generic.vhd
./vhdl/a.b-Datapath.core/a.b.c-ALU.core/a.b.c.e-loadhigh.vhd
./vhdl/a.b-Datapath.core/a.b.c-ALU.vhd
./vhdl/a.b-Datapath.core/a.b.d-memory_stage.vhd
./vhdl/a.b-DLX_datapath.vhd
./vhdl/a-DLX.vhd
}

analyze -library WORK -format vhdl $vhdfiles

#2) ...and compile/maintain the following by hand -.- (there's no automatic way to choose the right architecture in files that have several, unless we establish a convention about the order in which architectures are specified - e.g. first architecture in the source file gets used).
#Dictionary containing (entity, architecture) pairs; note there's only one chosen architecture to be synthesized for each of the entities.
#Entity is key, architecture is value (represented as a list with only one element, for flexibility).
#More fields can be added here as needed (e.g. custom constraints for each component) by adding elements to the list.

set dict {

    "FA" { "BEHAVIORAL" }
    "IMM_EXTENDER" { "DATAFLOW" }
    "IV" { "BEHAVIORAL" }
    "LATCH_GENERIC" { "behavioural" }
    "MUX21_GENERIC" { "STRUCTURAL" }
    "MUX21" { "STRUCTURAL" }
    "MUX_GENERIC" { "BEHAVIORAL" }
    "ND2" { "ARCH1" }
    "REG_GENERIC" { "PIPPO" }
    "DELAY_BLOCK" { "structural" }
    "RCA" { "STRUCTURAL" }
    "ACC" { "Structural" }

}

#actual synthesis step
foreach {entity argslist} $dict {
  elaborate $entity -architecture [lindex $argslist 0] -library WORK 
  compile -exact_map
  set getout [gets stdin]
  if {[string match "q" $getout] == 1} {return}
}


#write_file -format vhdl -hierarchy -output ./synthesized/CU_HW_netlist.vhd
#report_timing -nworst 10 -max_paths 10 > ./synthesized/CU_HW_timing.rpt
