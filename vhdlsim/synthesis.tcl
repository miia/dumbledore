
#1) Get all your non-testbench .vhd files with "find . -name "*.vhd" -not -name "tb*" | sort" !
analyze -library WORK -format vhdl {000-globals.vhd 000-opcodes.vhd 01-ceillog.vhd 01-log2.vhd 01-txt_util.vhd 02-fa.vhd 02-imm_extender.vhd 02-iv.vhd 02-latch.vhd 02-mux21_generic.vhd 02-mux21.vhd 02-mux_generic.vhd 02-nd2.vhd 02-reg_generic_enabled.vhd 02-reg_generic.vhd 03-delay_block.vhd 03-rca.vhd 04-ACC.vhd a.a-CU_HW.vhd}

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

    # "DLX_CU" { "CU_HW" }

    # "DLX_DATAPATH" { "dlx_simple" }   ;# ♬ it's not so simple anymooore ♬

    # "IRAM" { "IRam_Beh" } ;#TODO: should we synthesize the behavioral Instruction RAM? probably not.

}

#actual synthesis step
foreach {entity argslist} $dict {
  elaborate $entity -architecture [lindex $argslist 0] -library DEFAULT 
  compile -exact_map
  set getout [gets stdin]
  if {[string match "q" $getout] == 1} {return}
}


#write_file -format vhdl -hierarchy -output ./synthesized/CU_HW_netlist.vhd
#report_timing -nworst 10 -max_paths 10 > ./synthesized/CU_HW_timing.rpt
