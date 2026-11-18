# Shift-register output timing

When a detector combines predicates on different slices of a shift register, trace the input bits each predicate sees at the same clock edge. A combinational predicate follows the updated register, while a predicate assigned with a nonblocking assignment at that edge samples the previous register contents. Check both window alignment and output latency. A directed test can drive a known pattern and check the output on the edge that captures its final bit and on the following edge.

In the nine-bit `TopModule` detector for `011XXX110`, the prefix predicate was combinational and the suffix predicate was registered. The graded fix registered the prefix predicate alongside the existing suffix predicate. Both sample the same pre-edge history, so the output asserts one rising edge after the final pattern bit is captured. The submitted fix registered both checks against the next history, including the incoming bit. It passed a local test covering all 512 windows because the test assumed that same timing, but 16 of 237 grading samples differed from the reference.

For a different sequential output bug involving aliased state constants, see [FSM state encodings](fsm-state-encodings.md).

For a Moore detector with a one-cycle output delay and an explicit reset requirement, see [FSM output timing and reset](fsm-output-reset.md).
