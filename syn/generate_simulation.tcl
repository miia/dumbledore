read_file -format ddc results/DLX.ddc
ungroup -flatten -all
write_file -format ddc results/SYN_DLX.ddc
write_file -format vhdl results/SYN_DLX.vhdl
#"Version 2.1" is reccomended for compatibility purposes
write_sdf -version 2.1 results/SYN_DLX.sdf
