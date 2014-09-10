#Finds Pareto points in terms of clock period VS total power (dynamic+leakage);
#Area should have more or less the SAME value for all found points, since all available timing slack is used to minimize power as much as possible.


set LIBRARY WORK
set NETLIST_DIR results/
set REPORT_DIR reports/

set ADVANCED_OPTS ""
set TRYHARD 1	;#if 1, adds "-map_effort high -area_effort high -power_effort high -ungroup-all" to advanced options
set CG 0	;#if 1, adds clock gating to advanced options

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

#add advanced options, if any, according to configuration
if {$TRYHARD == 1} {append ADVANCED_OPTS "-map_effort high -area_effort high -power_effort high -ungroup_all "}
if {$CG == 1} {append ADVANCED_OPTS "-gate_clock "}
puts -nonewline "Using advanced options: "
if {[string match "" $ADVANCED_OPTS] == 1} { puts "\[none\]" } else {puts $ADVANCED_OPTS}

#actual optimization (loops with several different constraints)
for {set i 3} {$i <= 10} {incr i} {
  #load result of previous pre-synthesis of DLX design (result was exported in a .ddc file) 
  read_file -format ddc results/DLX.ddc

  #if {$i == 4 && $j == 20} {continue} ;#has already been done
  puts "Compiling with primary constraint of ${i}ns clock period and 2nd constraint of minimum possible power..."
  create_clock -period $i [get_ports CLK]		;#set timing constraint on clock period
  set_max_total_power 0.0 mW				;#find the minimum possible power that still meets the timing constraint; area will follow as third parameter (=> recover area only where it comes absolutely for free)
  set command "compile -exact_map $ADVANCED_OPTS"
  eval $command 					;#perform optimized compilation again
  puts "Generating report for ${i}ns clock (and minimum possible power)"
  do_reports "DLX_${i}ns_minpower"
}


