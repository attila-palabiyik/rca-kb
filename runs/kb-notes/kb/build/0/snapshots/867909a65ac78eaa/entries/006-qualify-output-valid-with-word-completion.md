# Qualify output valid with word completion

When debugging a registered valid-only packer, compare the full output-valid predicate with the data register's write condition on the same edge. Check both the input-valid gate and every completion count in the data-write branches. If the counter advances only on accepted input, a gap at a completion count leaves it waiting for the completing beat.

Two 24-to-128-bit `TopModule` tasks exposed different failures in this predicate.

- The original `|| valid_in` asserted `valid_out` on ordinary input beats and on idle cycles at counts 5, 10, and 15. Gating the completion predicate with `&& valid_in` matched the reference on all 261 grading samples.
- Another version already gated with `&& valid_in`, but its completion counts were 5, 12, and 15, while `data_out` was written at 5, 10, and 15. This missed the output pulse at count 10 and asserted it with stale data at count 12. Changing 12 to 10 matched the reference on all 261 grading samples.

A directed test should include ordinary valid beats, idle cycles at completion counts, and a continuous stream across a counter wrap. Check the flag on every cycle so the test catches both missing and extra pulses. A bit-stream scoreboard independently checked 35 packed words in Icarus Verilog for the count fix, including input gaps, counter wraparound, and reset.
