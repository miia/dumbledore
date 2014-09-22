# Physical layout #

After the synthesis stage, physical layout was performed according to the guidelines from lab sessions, plus some added steps for Clock Tree Synthesis:

- for power grid distribution, the two top layers were reserved for the two power rings (Vdd and GND) and a certain number of power stripes; 
- 
- 
- 

Unfortunately, the resulting layout has a large negative slack of -12ns, due to the fact that the placement tool placed the Data Memory very far from the ALU output register (and thus creating a very long critical path);

Timing results could greatly be improved by either

- explicitly guiding the placement of the memory block near to the ALU output TODO-footnote
- repeating physical layout starting from a synthesis result targeted for 2ns; this would start from a version more aggressively optimized for timing, and even with the delays introduced by Encounter, 8ns should be within reach (although total power consumption would surely be increased).


