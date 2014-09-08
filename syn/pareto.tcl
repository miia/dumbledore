set LIBRARY WORK
set NETLIST_DIR results/
set REPORT_DIR reports/

proc do_reports {filename} {
  variable NETLIST_DIR
  variable REPORT_DIR
  write_file -format vhdl -hierarchy -output $NETLIST_DIR/$filename.vhd
  write_file -format verilog -hierarchy -output $NETLIST_DIR/$filename.v
  write_file -format ddc -hierarchy -output $NETLIST_DIR/$filename.ddc
  report_area -nosplit > $REPORT_DIR/${filename}_area.rpt
  report_timing -nworst 10 > $REPORT_DIR/${filename}_timing.rpt
  report_power > $REPORT_DIR/${filename}_power.rpt
}

#load result of previous pre-synthesis of DLX design (result was exported in a .ddc file) 
read_file -format ddc results/DLX.ddc

for {set i 4} {$i < 10} {incr i} {
  puts "Compiling with target clock period of $i ns..."
  create_clock -period $i [get_ports CLK]	;#set timing constraint on clock period
  compile -exact_map				;#perform compilation (optimization) again
  puts "Generating report for $i ns clock"
  do_reports "DLX_${i}_ns"
}


