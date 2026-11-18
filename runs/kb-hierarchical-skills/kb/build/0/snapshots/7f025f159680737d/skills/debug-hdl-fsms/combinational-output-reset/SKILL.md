---
name: combinational-output-reset
description: Check asynchronous reset behavior when changing clocked HDL state-machine outputs to a combinational state decode.
---

# Reset in a combinational state decode

- Trace the reset path to both the state register and the outputs. If the outputs must be zero whenever reset is asserted, give reset priority in the combinational output block. Use blocking assignments and include reset in the sensitivity list, such as with `always @(*)`.
- Check startup separately from a warm reset. Start with reset asserted before any rising clock edge and observe the outputs before the first clock. Also assert reset between edges while each result is active, then check that the first complete group after release produces its result on time. A warm-reset check after the state register has settled can pass with a state-only decode.

In the graded `TopModule` detector for nonoverlapping groups of six bits matching `011100`, the submitted combinational decode of the success and failure states passed local tests of all ordered pairs of six-bit groups and resets applied after time zero. The grader reported one mismatch in 1,215 samples. The supplied reference preserved the original transition logic and explicitly forced both outputs low when `rst_n` was low. The report did not identify the failing sample. A direct reset branch avoids depending on the state register having reached its reset state before the outputs clear.
