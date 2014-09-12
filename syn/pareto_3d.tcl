#Finds Pareto points in terms of clock period VS total power (dynamic+leakage) VS area;
#Clock period varies at each outer iteration; inner iterations set the total power ALWAYS GREATER than the minimum possible value for that clock period; => area is free to vary, using the slack left after the power optimization pass.

#NOTE: currently does not work - apparently, DC is happier minimizing power BEYOND the requested constraint, rather than also trying to satisfy the area constraint.

set LIBRARY WORK
set NETLIST_DIR results/
set REPORT_DIR reports/

set ADVANCED_OPTS ""
set TRYHARD 1	;#if 1, adds "-map_effort high -area_effort high -power_effort high -ungroup-all" to advanced options
set CG 0	;#if 1, adds clock gating to advanced options

#dictionary containing, for each of the target clock periods [ns], the (approximate) minimum power obtained previously [mW] using pareto_2d.tcl; each of these will be used as "base" power for the corresponding clock period.
set mpdict {

    3    95.4
    4    74.0
    5    61.1
    6    53.2
    7    45.3
    8    39.8
    9    36.6
    10   33.3

}

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

  set minpower [lindex $mpdict [expr [lsearch $mpdict $i] + 1]]  ;#minimum possible power previously obtained for the current clock period (using pareto_2d)
								   #(NOTE: MUST be expressed in mW)
  for {set j 10} {$j <= 20} {set j [expr $j+10]} {
    #load result of previous pre-synthesis of DLX design (result was exported in a .ddc file) 
    read_file -format ddc results/DLX.ddc

    #if {$i == 4 && $j == 20} {continue} ;#has already been done

    ;#set timing constraint on clock period:
    create_clock -period $i [get_ports CLK]

    ;#set maximum total power constraint:
    set targetpow [expr $minpower+$j]
    set_max_total_power $targetpow mW

    ;#third optimization objective: with any slack left, minimize area AS MUCH AS POSSIBLE
    set_max_area 0.0

    puts "Compiling with target clock period of $i ns and target total power of $targetpow mW..."

    ;#perform optimized compilation again
    set command "compile -exact_map $ADVANCED_OPTS"
    eval $command
    puts "Generating report for $i ns clock and $targetpow mW total power"
    do_reports "DLX_${i}ns_minpowerplus${j}mW"
  }
}


