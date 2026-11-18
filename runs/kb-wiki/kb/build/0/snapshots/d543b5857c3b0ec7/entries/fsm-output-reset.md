# FSM output timing and reset

When a Moore FSM should report a result on the edge that enters a terminal state, decode the current state in a combinational block. A separate clocked block that reads the current state on that same edge sees the pre-edge value and delays the result by a cycle. When the output must be low while reset is asserted, give reset priority in the combinational block. Resetting the state in a separate clocked block only clears the decode once the state reset has propagated.

In the six-bit, non-overlapping `TopModule` detector for `011100`, the original clocked output block cleared both outputs during reset and reported the result one edge late. The submission changed it to `always @(*)` with direct decodes of the success and failure states, but omitted the output block's reset check. Local Icarus tests passed all 4,096 ordered group pairs and sampled reset after the state update had settled. Grading reported one mismatch in 1,215 samples. The supplied correct fix used a combinational state decode with an explicit active-low reset branch that clears both outputs. The grading report did not identify the failing sample.

When checking this change, verify that the output asserts on the edge that captures the last bit and drops on the next edge. Exercise reset while a result is asserted, during a partial group, and while reset is held low at startup when the simulation setup permits it. Check that sampling after the state has already settled does not mask whether the output block directly honors reset.

For a separate six-bit detector bug where a truncated state literal asserted `not_match` early, see [FSM state encodings](fsm-state-encodings.md#check-for-truncation-in-sized-state-literals). For register sampling in another detector and a counter that requires a one-cycle flag delay, see [Shift-register output timing](shift-register-output-timing.md).

When the output asserts at the intended edge and later behavior diverges, check both exits from its state. See [FSM transition tables](fsm-transition-tables.md).

For traffic light variants whose supplied fixes retained the idle reset and registered light stages, see [timer-driven exits](fsm-transition-tables.md#timer-driven-exits-with-registered-outputs) and [reload polarity at the visible output edge](fsm-transition-tables.md#check-reload-polarity-at-the-visible-output-edge).

## Register the flag for a pulse on the following edge

In the overlapping `1011` `TopModule` variant with a combinational `flag`, the transition table already handled overlap. The original decode of `state == S4` raised `flag` immediately after the edge that sampled the final `1`. The supplied fix registered that same decode on `posedge clk` with an asynchronous active-low reset. The flag samples the pre-edge state, so it rises on the following edge while the FSM continues processing input. Decoding `nstate` in the clocked block would report the match on the edge that samples the final bit.

The submission updated `flag` in the state register block and used blocking assignments in the next-state block. It matched all 153 grading samples. The supplied fix changed only the flag block. Local Icarus Verilog simulation checked all 4,096 twelve-bit streams against the four samples preceding each edge. It also checked reset with a match pending and while the pulse was high. For `10110111`, the matches finish at edges 4 and 7 and the pulses start at edges 5 and 8, counting from the first sampled bit.

Two other overlapping `1011` `TopModule` variants already had the required registered flag. One missed matches after a partial mismatch because of a [transition error](fsm-transition-tables.md#preserve-partial-matches-in-overlapping-detectors). The other could never reach the match state because of [duplicate state encodings](fsm-state-encodings.md#duplicate-encodings-in-an-overlapping-detector).
