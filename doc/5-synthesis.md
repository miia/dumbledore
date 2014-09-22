# Synthesis #

Once simulation yielded satisfactory results, synthesis was performed using Synopsys design Compiler; several different synthesis runs were performed starting from the same RTL netlist, and each time different constraints were imposed.

## Critical path analysis ##

First of all, a tentative synthesis and a quick critical path analysis was performed, to spot strongly unbalanced paths.

A large critical path was found in the following route:
- the old Program Counter value is output from the PC output register,
- goes to the BPU,
- passes through the corresponding BHT line, which predicts *taken*,
- the *taken* prediction, in turn, causes the multiplexer inside the PC accumulator to select the *immediate* input and feed it into the PC accumulator
- and the new Program Counter value is computed using the Ripple-Carry Adder inside the accumulator (which is actually responsible for most of the delay).

Such a critical path was largely due to the type of adder used within the PC accumulator: once the RCA was swapped with a P4 adder and synthesis was repeated, the critical path was different and much closer to the delay of the less-critical paths.

## Synthesis script ##

The attached TCL script "pareto_2d" was used for this purpose; its algorithm is fully documented in code comments, but at a high level it works in the following way:

- a loop selects the constraint for the clock period;
- according to the script's configuration options, additional synthesis options and constraints are activated:
    - it is possible to set either a maximum fanout or a maximum load capacitance on the high-fanout "reset" net (see below for more details);
    - it is possible to choose a different wire load model from the default (a less optimistic one has been used in order to partially compensate for the layout phase);
    - clock gating is deactivated by default.
- for each iteration (each one aiming at a different target clock period), some slack is left while optimizing timing; all this slack is used in a second optimization run, to minimize power consumption (i.e., try to obtain the best possible timing, then use all the available slack to optimize power as much as possible, until there is no more slack).
- in this way, each iteration obtains a new Pareto point on the timing-power plane.+;
- timing, power and area reports are generated for every synthesis run.

Data were extracted from the reports using the bash script extract_data_from_reports.sh, and plotted using gnuplot; this allowed to trace the Pareto curve shown in figure TODO.

## A note about the max capacitance / max fanout constraints ##

Since the "reset" net obiously has a high fanout, the script allows to set a constraint on the maximum fanout or the maximum load capacitance of the net; Design Compiler will then insert buffers along the interconnects to ensure the constraints are met.

Each of the two approaches has its drawbacks, and can be used only heuristically:

- since synthesis takes place before the actualy place and routing phases (which happen during physical layout), any capacitive load estimate based on the wire load model may be very inaccurate;
- an alternative heuristic would be to set a constraint on the maximum fanout of the net; the fanout *can* be controlled precisely, however its relation to the total load capacitance is only indicative, since this criterion doesn't take into account the interconnections' length, and only considers the number and capacity of connected loads.

The only viable alternative has been to set conservative limits during synthesis, and then check during the layout phase that the reset net wasnt't responsible for the critical path (which ultimately turned out to be from the ALU output to the Data Memory input).

The buffers added by Design Compiler during synthesis would then be placed freely by Cadence Encounter (like any other component) during time-driven optimization (i.e., with the objective of minimizing delay).

A different approach was followed for the clock net, which is also a high-fanout net, but has the additional issue of *clock tree balancing*: in other words, while the loads connected to the reset net could safely receive the reset signal at slightly different times, it was critical that *all* components receiving the clock rising edge would receive it with as little skew as possible.

This issue is known as *clock tree balancing*, and the main problem is that buffer insertion must be delayed all the way to the physical layout phase, since the optimal number of buffers will also depend on the actual length of the interconnections (which in turn depends on components placement).

In order to achieve this, Design Compiler is instructed not to insert any buffer on the clock net (as it will be taken care of later during the layout phase); moreover, since the "untouched" clock net would have a very large delay, DC is configured not to count it in any timing report or optimization cost function.

This is done by using the command create_clock in pareto_2d.tcl (which internally calls set_dont_touch e set_ideal_net, as well as setting the actual timing constraint).

