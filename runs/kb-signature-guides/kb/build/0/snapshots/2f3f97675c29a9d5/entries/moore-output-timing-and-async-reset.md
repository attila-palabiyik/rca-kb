# State-derived output timing and asynchronous reset

Applies when a flag derived from an FSM state or counter value asserts on the wrong clock, or when a state-only decode differs during initialization or reset.

Compare the register and flag immediately before and after the edge where the register reaches the value of interest. A combinational decode follows the updated value after the edge. A clocked decode using a nonblocking assignment samples the pre-edge value and reports that condition in the following cycle. Use the required timing to choose the decode, then check reset separately.

## Decimal up/down counter

In the decimal counter's `TopModule.sv`, both count sequences already wrapped correctly. The combinational `zero` decode asserted as soon as `number` reached 0 and also asserted upon reset release with the count still at 0. The requirement called for a pulse in the next cycle. On an up-count, check the three consecutive post-edge pairs `(number, zero) = (0, 0), (1, 1), (2, 0)`. On a down-count, check `(0, 0), (9, 1), (8, 0)`. Assert reset between rising edges while `zero` is high and check that both registers clear. Release reset between edges and check that `zero` stays low until the first rising edge, when it samples the reset count of 0.

The fix changed the flag to a rising-edge register with an active-low asynchronous clear and left the count logic intact. All 289 grading samples matched. The reference also registered the comparison against the pre-edge count and cleared `zero` asynchronously.

## Overlapping 1011 detector

In `TopModule.sv`, the combinational `flag` decode asserted on the same rising edge that sampled the final `1` and moved the FSM into `S4`. The specification called for a one-cycle pulse starting on the following rising edge. For an isolated `1011` followed by `00`, check that `flag` reads `0, 1, 0` after edges 4 through 6. The state encodings were distinct, and the transition table already preserved overlap both after a complete match and after a partial mismatch.

The reference and submitted fixes registered `state == S4` on `posedge clk` with an active-low asynchronous clear. All 153 grading samples matched. The local Icarus test checked all 4,096 twelve-bit streams with an extra sample to expose a match ending on the final bit. It also asserted reset between rising edges both after a match with its pulse pending and while a pulse was high. When checking timing with a stream model, compare the flag after each edge against the four bits sampled before that edge, then add the current bit to the history.

## Six-bit sequence detector

1. Trace the state and output on the edge that consumes the final input. A separate clocked block reading the state sees its pre-edge value because the state register uses a nonblocking assignment. In the six-bit detector, the FSM entered `s6` or `sf6` on the sixth edge and consumed the next group's first bit on the seventh. The state encodings were distinct and the transitions already preserved group boundaries. The clocked output decode delayed the result until the seventh edge.
2. Check the reset behavior of the output block separately from that of the state register. The original block explicitly cleared both outputs when `rst_n` was low. The submitted state-only combinational decode depended on the state register reaching `idle`. Such a decode can return `X` while the state is unknown and can still show the old result until the reset-driven state update takes effect. The supplied reference explicitly drove both outputs low when `rst_n` was low and decoded the terminal states otherwise. If a wildcard sensitivity list is required, put the reset check inside `always @*` so the reset signal is included automatically. Keep the output decision independent of the incoming data when it depends only on state and reset.
3. Test the result immediately after the final sampling edge and verify that it clears on the next edge. Assert reset between clock edges while a result is high, and include an initialization case with reset held low. When checking reset event ordering, distinguish a check after the combinational block runs from a later check after the nonblocking state update has settled. The local tests covered all 4,096 ordered group pairs and checked reset after a `#1` delay. That delay let the state update settle, so the test could not distinguish explicit output clearing from eventual clearing through `idle`.

Source task involved `TopModule.sv`, a non-overlapping detector for `011100`. The state-only combinational fix missed 1 of 1,215 grading samples. The reference used a reset-gated combinational decode with an explicit sensitivity list containing `pstate`, `data`, and `rst_n`. The grader did not identify the failing sample, so its exact trigger is unknown.
