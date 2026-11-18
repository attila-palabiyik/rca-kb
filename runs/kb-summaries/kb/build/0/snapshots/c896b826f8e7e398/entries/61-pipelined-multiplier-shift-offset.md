# Off-by-one shift in a pipelined multiplier

In the unsigned 4-bit multiplier in TopModule.sv, the partial product selected by multiplier bit i was shifted by i-1. This gave bit 0 a negative shift count and weighted the remaining three bits one position too low. Changing the shift count to i assigns each selected partial product its proper binary weight while preserving the two register stages and their asynchronous reset.

An Icarus Verilog scoreboard streamed all 256 operand pairs on consecutive cycles and checked each result on the next rising edge. It also asserted reset between edges with a nonzero output and another product pending, then verified both pipeline stages cleared. The first test command was rejected because its cleanup used rm -f. Deleting the two named temporary files with pathlib allowed the simulation and cleanup to run.

For shift-and-add multipliers, map each selection bit to its binary weight before changing the adders. Continuous inputs and a mid-cycle reset verify the register boundaries separately from the arithmetic.
