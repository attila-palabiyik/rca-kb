# Check when a handshake counter advances

**Check** whether a counter of accepted input beats advances on the same edge as input capture. Evaluate all four combinations of the `ready` and `valid` values sampled at that edge. A valid-ready transfer occurs when both are high, so a counter's hold condition is `!ready || !valid`.

- **The counter advances without a transfer.** Correct the counter guard and verify that the count holds during both a gap in `valid` and a cycle with `valid` high while `ready` is low. If `ready` is registered, check the first edge out of reset using its pre-edge value.
- **The counter advances only on a transfer.** For missing or misaligned word completion, [check whether the counter reaches the completion count](transfer-counter-wrap.md).

**Observed in `TopModule.sv`**, a six-bit serial-to-parallel converter. The input shift register captured on `ready_a && valid_a`, but the counter held only on `~ready_a && ~valid_a`. Thus the counter advanced when exactly one handshake signal was high. The reference changed the hold condition to `~ready_a || ~valid_a` alone. It retained registered `ready_a`, which was low in reset and went high on the first rising edge after reset, and retained the count-only `valid_b` condition. The submitted fix made `ready_a` constantly high and gated `valid_b` with `valid_a`. Its local tests expected both of those changes and passed, but 16 of 151 graded samples differed from the reference. The grading did not attribute individual mismatches to either change.
