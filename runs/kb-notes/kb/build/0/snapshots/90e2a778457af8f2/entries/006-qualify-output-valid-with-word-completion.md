# Qualify output valid with word completion

When debugging a registered valid-only packer, compare the output-valid predicate and sampling edge with the data register's write condition. Check the input-valid gate, every completion count, and whether both outputs use the same pre-edge state. If the counter advances only on accepted input, a gap at a completion count leaves it waiting for the completing beat.

Three 24-to-128-bit `TopModule` tasks exposed different failures in the output handshake.

- The original `|| valid_in` asserted `valid_out` on ordinary input beats and on idle cycles at counts 5, 10, and 15. Gating the completion predicate with `&& valid_in` matched the reference on all 261 grading samples.
- Another version already gated with `&& valid_in`, but its completion counts were 5, 12, and 15, while `data_out` was written at 5, 10, and 15. This missed the output pulse at count 10 and asserted it with stale data at count 12. Changing 12 to 10 matched the reference on all 261 grading samples.
- A third version had the correct counts and input-valid gate, but drove `valid_out` combinationally. With continuous input it asserted while `data_out` still held the previous word, then dropped when the completing edge advanced the counter and wrote the new word. Registering the existing predicate on the same rising edge as `data_out` and clearing `valid_out` on asynchronous reset matched the reference on all 261 grading samples.

A directed test should include ordinary valid beats, idle cycles at completion counts, and a continuous stream across a counter wrap. Check the flag and data together after the rising edge has settled. Change the inputs between rising edges and check that the registered outputs hold, except on reset. Icarus Verilog bit-stream scoreboards verified 35 packed words for the count fix and 80 for the registration fix, including input gaps, counter wraparound, and reset.
