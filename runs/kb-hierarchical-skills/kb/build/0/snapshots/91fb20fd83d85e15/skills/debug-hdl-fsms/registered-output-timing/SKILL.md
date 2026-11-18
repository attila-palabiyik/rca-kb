---
name: registered-output-timing
description: Diagnose cycle misalignment in Verilog and SystemVerilog sequence detectors and between registered payload and valid outputs in stream converters.
---

# Registered output timing

- Trace each predicate across a rising edge. A clocked comparison of a shift register reads its pre-edge value, while a combinational comparison of the same register sees the updated value after nonblocking assignments settle. Combining the two predicates can mix adjacent windows.
- Compare the existing output pipeline with the requested timing before editing. If the intended output is a registered comparison of the stored window, evaluate every predicate using that pre-edge window. Comparing against the next shift-register value instead advances detection by a cycle. Preserve reset initialization and add a sample-valid gate only when the required startup behavior calls for one.
- Verify timing with an isolated match. Check the output immediately after the final input bit is sampled and again after the following edge, allowing nonblocking assignments to settle. Test reset separately, including whether reset-filled history contributes to early windows. A testbench that assumes the proposed latency can pass every pattern and still miss the timing bug.

In the graded TopModule detector for `011XXX110`, the suffix check already read the pre-edge window. The reference clocked the prefix check as well, so both checks used the same stored window and the result appeared one edge after the last bit entered the shift register. The reference retained zero-initialized history without a sample-count gate. A rewrite that compared the next window and added a nine-sample startup gate disagreed with the reference on 16 of 237 samples.

## Stream width converters

- If `valid_out` marks a newly completed word, trace the exact condition that loads `data_out` at the clock edge. A counter can remain at a completion position during an input gap. When the current input supplies the final bits, require both that position and acceptance of the input on that edge. Check a valid input before completion, an idle cycle at the completion position, and the accepted input that completes the word.
- In the graded 24-to-128-bit `TopModule`, `data_out` loaded at pre-edge counts 5, 10, and 15 when `valid_in` was high. Changing the output-valid condition from OR to AND matched all 261 reference samples. The existing counter and data slices already carried the remaining bits into the next word.
