# Results & conclusions #

A simple benchmark for this CPU is contained into the file *software/test_sqrt.asm*. This file computes the square root of a number (using fixed-point computing) using the bisection method to approximate the result until 1-LSB precision is achieved; this simple test can show most of the functionality of the CPU. In particular:

- procedure calling is possible (and nested calling too, by saving the content of R31 to memory before the second call), and is used to call an error function, which in turn calls a square function;

- as the square function implements multiplication by means of a loop, the correct BPU functionality is extremely influent to improve the performance of this algorithm. Running the simulation it can be seen that the 2-bits BHT gives a timing improvement of about 30% over the not-taken BPU and an even bigger one over the design without BPU (which would stall each branch instruction);

- Forwarding also improves a lot the performance of the CPU, as many instructions have direct dependencies over each other.



As shown in figure [1], this performance improvements are worthless if the CPU can't be fed appropriately.

![New frontiers for tail-recursive computing][1]

[1]: ./cat.jpg "New frontiers for tail-recursive computing"
