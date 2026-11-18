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

For a hexadecimal counter whose supplied fix registers the data alongside an existing zero flag, see [counter data and flag alignment](shift-register-output-timing.md#align-counter-data-with-an-existing-registered-flag).

## Register buffered outputs that feed a timer reload

In the pedestrian traffic light `TopModule` variant with a combinational final light stage, the state transitions at `cnt == 3` and the reload predicates such as `!green && p_green` were already correct. The combinational assignment made `green` follow `p_green` before the next rising edge, so the timer never sampled the `green=0, p_green=1` pair during a normal green entry. With no pedestrian request, that boundary showed green at count 1, then decremented to 0 instead of loading 60.

The supplied fix changed only the final light block to `always @(posedge clk or negedge rst_n)` with nonblocking assignments. It clears all three visible lights during reset and otherwise samples the buffered lights. On normal red-to-green entry, the state changes at count 2, `p_green` rises at 1, and the next edge shows green and 60 together. On that edge the timer samples the same pre-edge buffer as the output block, while the old visible green is still low. A pending request can cap the timer on the following edge. At startup, the fixed design shows all lights off at counts 9 and 8 on the first two rising edges after reset release, then shows red and 10 on the third.

The submission replaced the stages with a direct state decode and asserted red during reset. Its Icarus checks passed for the prose-based behavior, including requests at all 60 green counts. Grading reported 220 mismatches in 517 samples. The supplied fix preserves the original idle reset state and the existing counter and transition logic. The report gives no per-sample results.

When a timer reload compares a buffered light with its visible output, check which pre-edge values can differ and when the output samples the buffer. Check reset release separately from steady phase boundaries. For variants with the same kind of feedback but different faults, see [timer-driven exits](fsm-transition-tables.md#timer-driven-exits-with-registered-outputs) and [reload polarity](fsm-transition-tables.md#check-reload-polarity-at-the-visible-output-edge).
