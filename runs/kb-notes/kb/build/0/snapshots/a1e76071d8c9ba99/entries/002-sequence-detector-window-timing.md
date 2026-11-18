# Clock alignment across split signal paths

In the `TopModule` detector for `011XXX110`, the shift register and suffix flag updated on the rising edge, while the prefix flag was combinational. After each edge, the prefix flag inspected the history including the new input and the suffix flag represented the history from before the edge. The resulting `match` combined slices from different windows.

The reference fix registered the prefix flag on the same rising edge and active-low asynchronous reset as the suffix flag. Both flags then inspect the pre-edge shift-register value, and their AND reports a window one clock after its last bit was sampled. The reference clears the history to zero and evaluates it immediately after reset, so its first match can include a reset-padded leading zero.

The attempted rewrite compared both slices of the next shift-register value and required nine actual samples. Its exhaustive Icarus test passed against an oracle that assumed those same rules, but grading disagreed on 16 of 237 samples. For a split detector with a registered half, trace the existing clock stages before picking a latency. Drive a known match followed by another bit and check both edges around the expected pulse. Separately test the first possible match after reset to distinguish zero-filled history from a full-window guard.

## Incorrect prefix in the registered detector

In a separate `TopModule` task for `011XXX110`, both flags were already registered and sampled the same pre-edge history. The prefix comparison used `3'b001` for `a_tem[8:6]`. Changing that literal to `3'b011` matched the reference diff and all 237 grading samples. No alternate RTL fix was tried. An Icarus test checked all 512 complete windows at the existing registered latency and confirmed that asynchronous reset clears an active match. When both comparisons already sample the intended window, check their bit slices and literals before changing the clocked logic.

## Shift register with the input wired to the wrong end

In another `TopModule` task for `011XXX110`, both registered flags already read the correct slices of the same pre-edge history. The assignment `{a, a_tem[7:0]}` replaced only bit 8 and left bits 7 through 0 fixed. The reference changed only that assignment to `{a_tem[7:0], a}`, which shifts each saved bit toward bit 8 and captures the new input in bit 0. The flags still report a match one rising edge after the last bit is sampled, using the existing zero-filled reset state.

The submission corrected the shift but also registered the comparison of the window including the new input and reset the history to all ones. Those changes moved the pulse a cycle earlier and prevented matches that use a reset-padded leading zero. Icarus passed all 512 nine-bit combinations against a testbench that expected the revised timing and required nine post-reset samples. Grading differed on 16 of 237 samples.

For a broken shift chain, trace where each bit moves and leave already-aligned output stages and reset values intact unless the task requires a change. With the corrected shift and original flags, drive `011000110` followed by another bit and expect the pulse on the tenth rising edge. Immediately after reset, drive `11000110` followed by another bit and expect the pulse on the ninth rising edge because the window includes one reset zero. These two checks cover timing and startup behavior that an exhaustive test of complete windows can miss.

## Three-input minimum in `TopModule`

The first registered `slave_mod` produced the minimum of `a` and `b` from the previous sample, while the second registered instance compared that value with the current `c`. The reference fix changed only the `c1` block to capture `c` with a nonblocking assignment on the rising clock edge and clear it on the falling edge of `rst_n`. The second stage then receives operands from the same sample.

The submission made that timing fix and also renamed the existing `slave_mod` ports `a` and `b` to `data_a` and `data_b` to match the prose. Its Icarus test instantiated only `TopModule` and passed directed checks and 2,000 randomized triplets. Grading failed to compile with its testbench. The grading report gave no compiler diagnostic, and the reference retained the original port names. Preserve an existing helper module's signature during a localized fix, especially when its signal names differ from the prose. If compatibility needs verification, compile a direct helper instantiation using the original named ports as well as testing behavior through the top module.
