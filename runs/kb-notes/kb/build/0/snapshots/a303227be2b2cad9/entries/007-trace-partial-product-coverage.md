# Trace partial products through a registered adder tree

In `TopModule`, a 4-bit unsigned pipelined multiplier, each bit of `mul_b` selected one shifted partial product. The first registered adder summed `temp[0] + temp[1]`, while the second summed `temp[2] + temp[2]`, omitting the partial product for bit 3. Replacing the duplicate operand with `temp[3]` was the entire reference fix. All 43 grading samples matched.

For similar arithmetic trees, trace each generated term to the output and check that it contributes exactly once. A one-hot multiplier isolates a single term. When the input space is small, stream every input pair through the design and compare the output against the expected product at the correct cycle. An Icarus Verilog test verified all 256 pairs on consecutive cycles and confirmed that asserting reset between clock edges cleared the output and flushed pending work.
