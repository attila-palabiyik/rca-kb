# Missing output register in a 4-bit pipelined multiplier

TopModule correctly generated the four shifted partial products and registered their two pairwise sums. The output adder was combinational, so the product appeared on the same rising edge as the partial sums instead of advancing through a second registered stage. Moving that final sum into a positive-edge block with active-low asynchronous reset and using nonblocking assignments gave the requested latency and one result per clock.

The first attempt to run a self-authored simulation was rejected because the temporary directory cleanup used a recursive removal command. Removing only the named temporary files and the empty directory allowed the simulation to run. Icarus Verilog verified all 256 operand pairs on consecutive cycles, plus reset between clock edges while a result was pending.

For similar multiplier or adder-tree tasks, trace the register boundaries as well as the arithmetic. A stream of consecutive inputs and a reset with in-flight data distinguish a missing output register from an arithmetic bug.
