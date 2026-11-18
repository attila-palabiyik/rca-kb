# FSM output timing and reset

When a Moore FSM should report a result on the edge that enters a terminal state, decode the current state in a combinational block. A separate clocked block that reads the current state on that same edge sees the pre-edge value and delays the result by a cycle. When the output must be low while reset is asserted, give reset priority in the combinational block. Resetting the state in a separate clocked block only clears the decode once the state reset has propagated.

In the six-bit, non-overlapping `TopModule` detector for `011100`, the original clocked output block cleared both outputs during reset and reported the result one edge late. The submission changed it to `always @(*)` with direct decodes of the success and failure states, but omitted the output block's reset check. Local Icarus tests passed all 4,096 ordered group pairs and sampled reset after the state update had settled. Grading reported one mismatch in 1,215 samples. The supplied correct fix used a combinational state decode with an explicit active-low reset branch that clears both outputs. The grading report did not identify the failing sample.

When checking this change, verify that the output asserts on the edge that captures the last bit and drops on the next edge. Exercise reset while a result is asserted, during a partial group, and while reset is held low at startup when the simulation setup permits it. Check that sampling after the state has already settled does not mask whether the output block directly honors reset.

For aliased state constants, see [FSM state encodings](fsm-state-encodings.md). For register sampling and output latency in a different detector, see [Shift-register output timing](shift-register-output-timing.md).
