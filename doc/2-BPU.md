# Branch Prediction Unit (BPU) #

The BPU is implemented using a 2-bit Branch History Table (BHT): each row of the BHT keeps track of one (or more, see below) branch instruction, and tries to predict whether the next occurrence of that branch will be taken or not; this prediction is formed by keeping track of the last 4 occurrences of that same branch (2-bits BHT means that each contains 2 bits, so it can remember the last 2^2 occurrences of the associated branch).

In particular, each row of a 2-bit BHT can be thought of as a Finite State Machine having four possible states, from Strongly Not Taken (usually encoded as "00") to Strongly Taken ("11"): each time a branch prediction is needed, the corresponding BHT row outputs a prediction depending on its current value (Not Taken if the row contains "Strong/Weak Not Taken", Taken if it contains "Strong/Weak Taken"); after the branch has been executed, the corresponding BHT row is updated according to its result (increased towards "11" if the branch was taken, decreased towards "00" if it wasn't).



## How big should the BHT be? ##

Ideally, there should be one line in the BHT for each conditional branch instruction (and only for them, since no other instructions need to be tracked by the BHT); however, this would make it much more complicated to index the BHT entries.

On the other hand, it would be much simpler to have as many rows in the BHT as the number of instructions in the Instruction RAM, and index each row of the BHT, because it would make it possible to address the BHT rows by using the address of the corresponding branch instruction, but this would lead to a lot of wasted rows (since conditional branches are only a small part of the instructions in most programs).

The usual compromise is to have 2^k rows in the BHT, and then index each row by using the *lowest* k bits of the address of the branch instruction in the IRAM. Of course, some branch instructions may reside at addresses having the same lower k-bits, and this would result in a "collision" since both branches have to share the same BHT row during execution, but this is a relatively low risk (especially if the *lowest* k bits are used and not the highest ones - spatial locality hints that if a branch collides with another one, the previous one will be not executed anymore, while the new one will execute more times. Also, the highest ones are more likely to collide, because they can take a smaller set of values for any given size of the IRAM). Besides, even if a collision does occur, this will not cause any critical problems during execution: branch predictions are just a hint of what instructions the fetch stage should load in the next cycles, and if a prediction turns out to be wrong (for example because of a collision in the BHT), it will be corrected by flushing the pipeline.

Of course, this solution introduces a tradeoff between the BHT size and the possibility of collisions between different branch instructions that end up sharing the same row of the BPU; choosing a higher value of k will result in a bigger BHT, but it will decrease the chance of collisions (up to the point where k=CODE_ADDRESS_SIZE makes this possibility 0% ).


## IMPLEMENTATION ##

To implement a BPU based on a BHT, two things must be taken into consideration: the BPU must have a way to output its prediction when a branch instruction enters the pipeline, and then it must have a way to receive the actual branch result and use it to "update" its knowledge regarding that particular branch.

This is achieved by using a multiplexer at the BHT output, and a demultiplexer at the BHT input:

- whenever a prediction is requested for a certain branch instruction, the output of the corresponding BHT row is simply selected in the output multiplexer;
- three cycles later, when the branch instruction actually passes through the ALU and the branch condition is evaluated, the outcome of the branch (either Taken or Not Taken) is sent back to the BPU; here, the BPU receives the branch outcome through the input demultiplexer, together with a signal that activates the corresponding BHT row and allows it to update its state; the demultiplexer routes the branch outcome and the activation signal to the appropriate BHT row, since it kept track of which BHT row was used three cycles before.

## Inside the BHT: implementation of the BHT rows
Each row of the BHT is implemented as a tiny Finite State Machine, where the State Register is just two bits wide, and the State transition function (the combinational logic deciding the next state according to current state and inputs) is composed of two simple boolean functions that can be computed using a Karnaugh map; there isn't even an output transition function, because incidentally the output of the FSM is the most significant bit of its state.

![State-transition diagram for the BPU *per-row* state-machine](./BPU_fsm.pdf)
