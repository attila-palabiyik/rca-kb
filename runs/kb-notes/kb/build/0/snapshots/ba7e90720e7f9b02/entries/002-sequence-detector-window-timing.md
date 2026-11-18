# Clock alignment in a split sequence detector

In the `TopModule` detector for `011XXX110`, the shift register and suffix flag updated on the rising edge, while the prefix flag was combinational. After each edge, the prefix flag inspected the history including the new input and the suffix flag represented the history from before the edge. The resulting `match` combined slices from different windows.

The reference fix registered the prefix flag on the same rising edge and active-low asynchronous reset as the suffix flag. Both flags then inspect the pre-edge shift-register value, and their AND reports a window one clock after its last bit was sampled. The reference clears the history to zero and evaluates it immediately after reset, so its first match can include a reset-padded leading zero.

The attempted rewrite compared both slices of the next shift-register value and required nine actual samples. Its exhaustive Icarus test passed against an oracle that assumed those same rules, but grading disagreed on 16 of 237 samples. For a split detector with a registered half, trace the existing clock stages before picking a latency. Drive a known match followed by another bit and check both edges around the expected pulse. Separately test the first possible match after reset to distinguish zero-filled history from a full-window guard.
