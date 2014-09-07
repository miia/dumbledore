read_file -format ddc results/DLX.ddc
ungroup -flatten -all
#This command is necessary to avoid having into sdf file net names like a/b, as they are ungrouped by dc_shell but would be treated as hierarchical by modelsim
change_names -rules vhdl -hierarchy
write_file -format ddc -output results/SYN_DLX.ddc
write_file -format vhdl -output results/SYN_DLX.vhdl
#"Version 2.1" is reccomended for compatibility purposes
write_sdf -version 2.1 results/SYN_DLX.sdf
