# Trace the Gray-to-binary XOR chain

In the 4-bit Gray counter `TopModule`, the least significant binary bit XORed `gray_wire[0]` with `bin_out[3]`. The reference fix used `bin_out[1]`, the already-decoded bit immediately above it. The existing blocking assignments evaluate that chain from most significant to least significant bit within the clocked block.

The submitted fix computed the same chain with combinational wires and captured the complete decoded value with a nonblocking assignment. It matched all 421 grading samples. The one-line reference fix shows that the XOR operand was sufficient to repair the graded behavior. Icarus Verilog also verified the submitted fix across all 16 values, wraparound, and asynchronous reset during counting. No alternate repair failed.

For Gray-to-binary conversion, check that each decoded bit is the XOR of its Gray bit and the decoded bit immediately above it. Gray `0011` should decode to binary `0010` and exposes the skipped dependency. For a feedback counter, check the expected output on every edge through wraparound so the test covers both the value sequence and the hold cycles.
