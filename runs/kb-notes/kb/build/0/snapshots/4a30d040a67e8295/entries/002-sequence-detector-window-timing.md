# Clock alignment across split signal paths

In the `TopModule` detector for `011XXX110`, the shift register and suffix flag updated on the rising edge, while the prefix flag was combinational. After each edge, the prefix flag inspected the history including the new input and the suffix flag represented the history from before the edge. The resulting `match` combined slices from different windows.

The reference fix registered the prefix flag on the same rising edge and active-low asynchronous reset as the suffix flag. Both flags then inspect the pre-edge shift-register value, and their AND reports a window one clock after its last bit was sampled. The reference clears the history to zero and evaluates it immediately after reset, so its first match can include a reset-padded leading zero.

The attempted rewrite compared both slices of the next shift-register value and required nine actual samples. Its exhaustive Icarus test passed against an oracle that assumed those same rules, but grading disagreed on 16 of 237 samples. For a split detector with a registered half, trace the existing clock stages before picking a latency. Drive a known match followed by another bit and check both edges around the expected pulse. Separately test the first possible match after reset to distinguish zero-filled history from a full-window guard.

## Three-input minimum in `TopModule`

The first registered `slave_mod` produced the minimum of `a` and `b` from the previous sample, while the second registered instance compared that value with the current `c`. The reference fix changed only the `c1` block to capture `c` with a nonblocking assignment on the rising clock edge and clear it on the falling edge of `rst_n`. The second stage then receives operands from the same sample.

The submission made that timing fix and also renamed the existing `slave_mod` ports `a` and `b` to `data_a` and `data_b` to match the prose. Its Icarus test instantiated only `TopModule` and passed directed checks and 2,000 randomized triplets. Grading failed to compile with its testbench. The grading report gave no compiler diagnostic, and the reference retained the original port names. Preserve an existing helper module's signature during a localized fix, especially when its signal names differ from the prose. If compatibility needs verification, compile a direct helper instantiation using the original named ports as well as testing behavior through the top module.
