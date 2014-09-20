#Finds Pareto points in terms of clock period VS total power (dynamic+leakage);
#Area should have more or less the SAME value for all found points, since all available timing slack is used to minimize power as much as possible.


set LIBRARY WORK
set NETLIST_DIR results/
set REPORT_DIR reports/

#clock periods used for compilation will range from MIN_PERIOD<=clk<=MAX_PERIOD (expressed in ns)
set MIN_PERIOD 8
set MAX_PERIOD 8

set ADVANCED_OPTS ""

set TRYHARD 1	;#if 1, adds "-map_effort high -area_effort high -power_effort high -ungroup-all" to advanced options
set CG 0	;#if 1, adds clock gating to advanced options

set USE_MAX_FANOUT 1  ;#if 1, adds max fanout constraint for the high-fanout RESET signal - remember to set the value of MAX_FANOUT below
set MAX_FANOUT 10

set USE_WLM 0   ;#if 1, uses a non-default wire load model - remember to set the value of WLM to one of the WLM contained in the current library (which is specified in the .synopsys_dc.setup file).
set WLM "0K_hvratio_1_4"

proc do_reports {filename} {
  variable NETLIST_DIR
  variable REPORT_DIR

  #For each optimized design:

  #1- Save .sdc constraints file (contains information about the defined clock tree and its timing constraints, which will be used by the post-synthesis layout tool)
  write_sdc $NETLIST_DIR/$filename.sdc


  #2- Write post-synthesis HDL files: the VHDL file can be used in a simulation tool (e.g. Modelsim) for post-synthesis simulation with accurate timing information; the Verilog file will be used as starting point (together with the .sdc file) by the post-synthesis layout tool (Encounter).
  #write_file -format vhdl -hierarchy -output $NETLIST_DIR/$filename.vhd
  write_file -format verilog -hierarchy -output $NETLIST_DIR/$filename.v

  #3- Write the reports and a .ddc file (makes it possible to easily resume synthesis later).
  write_file -format ddc -hierarchy -output $NETLIST_DIR/$filename.ddc
  report_area -nosplit > $REPORT_DIR/${filename}_area.rpt
  report_timing -nworst 10 > $REPORT_DIR/${filename}_timing.rpt
  report_power > $REPORT_DIR/${filename}_power.rpt
  report_net_fanout > $REPORT_DIR/${filename}_fanout.rpt
}

#add advanced options, if any, according to configuration
if {$TRYHARD == 1} {append ADVANCED_OPTS "-map_effort high -area_effort high -power_effort high -ungroup_all "}
if {$CG == 1} {append ADVANCED_OPTS "-gate_clock "}
puts -nonewline "Using advanced options: "
if {[string match "" $ADVANCED_OPTS] == 1} { puts "\[none\]" } else {puts $ADVANCED_OPTS}

#actual optimization (loops with several different constraints)
for {set i $MIN_PERIOD} {$i <= $MAX_PERIOD} {incr i} {
  #load result of previous pre-synthesis of DLX design (result was exported in a .ddc file) 
  read_file -format ddc results/DLX.ddc

  #if {$i == 4 && $j == 20} {continue} ;#has already been done
  puts "Compiling with primary constraint of ${i}ns clock period and 2nd constraint of minimum possible power..."

  create_clock -period $i [get_ports CLK]		;#set timing constraint on clock period; note this includes "set_dont_touch" and "set_ideal_net"

  set_max_total_power 0.0 mW				;#find the minimum possible power that still meets the timing constraint; area will follow as third parameter (=> recover area only where it comes absolutely for free)

 if {$USE_WLM == 1} {set_wire_load_model -name $WLM}	;#characterize wires as a non-ideal load;

  #HIGH-FANOUT CLOCK SIGNAL:
  #clock tree will not have buffers inserted during synthesis; it will be left out of the optimization, so that buffers will not be inserted - they will be inserted with ACCURATE balancing by Encounter, after the routing phase.
  set_propagated_clock [all_clocks]     ;# specifies that the propagation delay is NOT zero; during synthesis, clock skew along the clock tree will be calculated according to the wire load model used, annotated when exporting the .sdc file, and later used by Encounter for Clock Tree Synthesis.

  #HIGH-FANOUT RESET SIGNAL:
  #differently from clk, balancing the tree is not fundamental here, so buffer insertion can be made in an approximate way by DC itself, during synthesis (see balance_buffer command later on)
  if {$USE_MAX_FANOUT == 1} {set_max_fanout $MAX_FANOUT RESET}
  ##set_dont_touch [get_ports RESET]
  ##set_ideal_net [get_ports RESET]
  ###set_input_delay 1.5 -clock CLK [get_ports RESET]

  #perform compilation, leaving CLK and RESET alone (no buffer insertion)
  set command "compile -exact_map $ADVANCED_OPTS"
  eval $command 					;#perform optimized compilation again

  #after compilation, perform (approximately) balanced buffer insertion on the RESET tree:
  ##balance_buffer -net [get_ports RESET]

  puts "Generating report for ${i}ns clock (and minimum possible power)"
  set filename "DLX_${i}ns_minpower"
  if {$CG == 1} {append filename "_CG"}
  if {$USE_WLM == 1} {append filename "_WLM"} ;#a non-default wire load model was used
  if {$USE_MAX_FANOUT == 1} {append filename "_MFO"} ;#a maximum fanout constraint was used
  do_reports $filename
}


