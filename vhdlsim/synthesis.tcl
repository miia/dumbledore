#TODO: update this to use a dictionary!! THEN extend it further.

analyze -library WORK -format vhdl {000-globals.vhd 000-opcodes.vhd 01-ceillog.vhd 01-log2.vhd 01-txt_util.vhd 02-fa.vhd 02-imm_extender.vhd 02-iv.vhd 02-latch.vhd 02-mux21_generic.vhd 02-mux21.vhd 02-mux_generic.vhd 02-nd2.vhd 02-reg_generic_enabled.vhd 02-reg_generic.vhd 03-delay_block.vhd 03-rca.vhd 04-ACC.vhd a.a-CU_HW.vhd}

elaborate FA -architecture BEHAVIORAL -library DEFAULT 
compile -exact_map
gets stdin

elaborate IMM_EXTENDER -architecture DATAFLOW -library DEFAULT 
compile -exact_map
gets stdin

elaborate IV -architecture BEHAVIORAL -library DEFAULT 
compile -exact_map
gets stdin

elaborate LATCH_GENERIC -architecture behavioural -library DEFAULT 
compile -exact_map
gets stdin

elaborate MUX21_GENERIC -architecture STRUCTURAL -library DEFAULT 
compile -exact_map
gets stdin

elaborate MUX21 -architecture STRUCTURAL -library DEFAULT 
compile -exact_map
gets stdin

#elaborate DLX_CU -architecture CU_HW -library DEFAULT 
#compile -exact_map

#write_file -format vhdl -hierarchy -output ./synthesized/CU_HW_netlist.vhd
#report_timing -nworst 10 -max_paths 10 > ./synthesized/CU_HW_timing.rpt
