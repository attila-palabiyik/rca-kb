# FSM output timing and reset

When a Moore FSM should report a result on the edge that enters a terminal state, decode the current state in a combinational block. A separate clocked block that reads the current state on that same edge sees the pre-edge value and delays the result by a cycle. When the output must be low while reset is asserted, give reset priority in the combinational block. Resetting the state in a separate clocked block only clears the decode once the state reset has propagated.

In the six-bit, non-overlapping `TopModule` detector for `011100`, the original clocked output block cleared both outputs during reset and reported the result one edge late. The submission changed it to `always @(*)` with direct decodes of the success and failure states, but omitted the output block's reset check. Local Icarus tests passed all 4,096 ordered group pairs and sampled reset after the state update had settled. Grading reported one mismatch in 1,215 samples. The supplied correct fix used a combinational state decode with an explicit active-low reset branch that clears both outputs. The grading report did not identify the failing sample.

When checking this change, verify that the output asserts on the edge that captures the last bit and drops on the next edge. Exercise reset while a result is asserted, during a partial group, and while reset is held low at startup when the simulation setup permits it. Check that sampling after the state has already settled does not mask whether the output block directly honors reset.

For a separate six-bit detector bug where a truncated state literal asserted `not_match` early, see [FSM state encodings](fsm-state-encodings.md#check-for-truncation-in-sized-state-literals). For register sampling in another detector and a counter that requires a one-cycle flag delay, see [Shift-register output timing](shift-register-output-timing.md).

When the output asserts at the intended edge and later behavior diverges, check both exits from its state. See [FSM transition tables](fsm-transition-tables.md).

Two overlapping `1011` `TopModule` variants already had the required one-cycle delay from the registered flag. One missed matches after a partial mismatch because of a [transition error](fsm-transition-tables.md#preserve-partial-matches-in-overlapping-detectors). The other could never reach the match state because of [duplicate state encodings](fsm-state-encodings.md#duplicate-encodings-in-an-overlapping-detector).

For traffic light variants whose supplied fixes retained the idle reset and registered light stages, see [timer-driven exits](fsm-transition-tables.md#timer-driven-exits-with-registered-outputs) and [reload polarity at the visible output edge](fsm-transition-tables.md#check-reload-polarity-at-the-visible-output-edge).
