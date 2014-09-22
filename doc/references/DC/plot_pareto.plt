set term postscript colour
set view 45,45,1,1
set size 3,3
set output "pareto.ps"
set dgrid3d 10,10
set hidden3d

set label "Clock period (ns)" at screen 1.0,0.3 center rotate by -25 font "LiberationSans,24"
set label "Total power (mW)" at screen 2,0.3 center rotate by 25 font "LiberationSans,24"
set label "Total cell area" at screen 0.2,1.5 center rotate font "LiberationSans,24"
splot "pareto.m" u 1:2:3 with lines
