# Preserve the sampled window when fixing a registered sequence detector

In the Verilog `TopModule` detector for `011XXX110`, the prefix comparison read the shift register combinationally while the suffix comparison was clocked. After each rising edge, the output combined the prefix of the newly shifted window with the suffix of the previous window.

The accepted fix clocked the prefix comparison with the same rising edge and asynchronous active-low reset as the suffix comparison. Both comparisons then used the pre-edge contents of the nine-bit shift register, so the output asserted one rising edge after the last bit of the pattern entered the register. The shift register kept its original zero reset value.

My submitted fix also aligned the comparisons, but it registered a comparison of the next window, including the current input, and changed the reset fill to ones to suppress startup matches. It passed a local test that assumed detection on the edge sampling the last bit, but grading reported 16 mismatches in 237 samples. The feedback establishes the reference timing and reset behavior, without identifying which mismatches came from each change.

In a separate `TopModule` task for the same pattern, both comparisons were already clocked. The prefix check used `3'b001` on bits `[8:6]`, and the suffix check correctly used `3'b110` on bits `[2:0]`. Changing the prefix literal to `3'b011` was the entire reference fix. That edit matched all 237 grading samples and preserved the pre-edge window and zero reset fill. A local Icarus Verilog test also checked all 512 windows against that timing. When both comparisons already sample the same window, check their slices and literals against the requested pattern before changing the sampling logic.

When fixing mixed combinational and registered checks, use the existing registered path to infer the intended sampling edge when the specification is ambiguous. Keep the reset fill unless the task calls for changing startup behavior. In a testbench, label the edge that shifts in the final bit and the edge that should assert the output, and check both.
