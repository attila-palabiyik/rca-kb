# Flag latency in an overlapping `1011` detector

TopModule entered match state `S4` on the rising edge that sampled the final bit. Its combinational decode asserted `flag` immediately after that edge, one cycle earlier than required. The state transitions already supported overlap.

The submission passed all 153 grading samples. Both the submission and the published reference clocked `flag` on the rising edge, assigned `flag <= (state == S4)` using the pre-edge state, and cleared it asynchronously on active-low reset. For `10110111`, matches end at samples 4 and 7, and the flag pulses after rising edges 5 and 8. A temporary Icarus test also passed all 4,096 twelve-bit streams and checked asynchronous reset during a pulse.

For FSM output timing bugs, label the edge that samples the final bit and the edge that should start the pulse. Check whether the output decodes the state after the edge or registers the state from before it. Add a trailing clock when testing a delayed pulse from a match that ends on the last input bit.
