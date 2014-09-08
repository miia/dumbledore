set LIBRARY WORK
set NETLIST_DIR results/
set REPORT_DIR reports/

proc do_reports {filename} {
  variable NETLIST_DIR
  variable REPORT_DIR

  #NOT YET - annotated vhdl and verilog files take time to produce, and they're only needed for the design that will be fed into Encounter for physical layout (or back into ModelSim for gate-level simulation).
  #write_file -format vhdl -hierarchy -output $NETLIST_DIR/$filename.vhd
  #write_file -format verilog -hierarchy -output $NETLIST_DIR/$filename.v

  #for each optimized design, only write the .ddc file (to easily resume later) and the reports.
  write_file -format ddc -hierarchy -output $NETLIST_DIR/$filename.ddc
  report_area -nosplit > $REPORT_DIR/${filename}_area.rpt
  report_timing -nworst 10 > $REPORT_DIR/${filename}_timing.rpt
  report_power > $REPORT_DIR/${filename}_power.rpt
}

#load result of previous pre-synthesis of DLX design (result was exported in a .ddc file) 
read_file -format ddc results/DLX.ddc

#actual optimization (loops with several different constraints)
for {set i 4} {$i <= 10} {incr i} {
  for {set i 20} {$i <= 70} {set i [expr $i+10]} {
    puts "Compiling with target clock period of $i ns and target total power of $j uW..."
    create_clock -period $i [get_ports CLK]	;#set timing constraint on clock period
    set_max_total_power $j mW			;#set maximum total power constraint
    compile -exact_map				;#perform compilation (optimization) again
    puts "Generating report for $i ns clock and $j uW total power"
    do_reports "DLX_${i}ns_${j}uW"
  }
}


