# Forwarding #
To avoid pipeline hazards if a register is read before being written, and avoid stalling the pipeline too, which would cost too much in terms of pipeline performance, forwarding of data into the datapath has been implemented. The outputs of the register file - after going into their normal pipeline registers and coming out from *pipe1a_out* and *pipe1b_out*, before entering the two muxes going into the ALU (for selecting between immediate values and register ones), pass through another 4-input mux. This mux's inputs are wired to the real register value, to the - flip-flop'd - ALU output, and to the writeback_data line (which has a register too, to ensure correct timing of data). It must be noticed that the input entering from the ALU has a different pipeline register w.r.t. the one entering the memory, as data memory is synchronous and thus its inputs must be latched instead of clocked, to ensure the setup times, while the ALU inputs are asynchronous.

The fourth signal entering the MUX is hard-wired to the values -4 (for A) and 0 (for B). The value -4 can be used by the datapath in case of a branch or a jump-and-link instruction, to compute (PC+)value+4 as an address for the jump.

Selection signals for this mux are driven by a special FORWARDER unit. Keeping in a FIFO queue the last 2 instructions that have entered the ALU (i.e. the one that just exited the ALU and the one that just exited memory - but still hasn't been written to registers), with their destination registers, the forwarding unit can switch in a correct way the selection signal. In particular, *giving precedence to the first instruction into the buffer* (as it could contain the most up-to-date value for the register), the selection signal is actived to fetch real value of the register, if no instruction into the queue has written to S1 or S2, or one of the two values from the ALU or from the memory, if destination address into the queue and source address into the IR coincide. For mux B, a branch or JAL instruction will select -4 as an output to allow computing either a fallback address or a return address.