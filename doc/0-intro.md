# Introduction #

This is the report for the DLX-pro project of group 28/2014 (Michele Iacobone - Simone Baratta).

This DLX has a complete support for the DLX's instruction set, with the exception of floating point operations and interrupt handling instructions (i.e. *trap*, *rfe*).

In addition, this processor features a 2-bit, BHT-based Branch Prediction Unit, and complete forwarding support. This leads to having a *almost*-fixed throughput of 1 instruction/clock cycle, with great improvements over the same processor with no BPU, or with a static BPU (i.e. predict-taken).



