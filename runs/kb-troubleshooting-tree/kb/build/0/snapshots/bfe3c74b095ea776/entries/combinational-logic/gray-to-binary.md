# Check each decoded bit in a Gray-to-binary conversion

**Check** that the most significant binary bit copies the most significant Gray bit. Each lower binary bit is the XOR of its corresponding Gray bit and the decoded binary bit immediately above it. Equivalently, each decoded bit is the reduction XOR of the Gray bits from the most significant bit down to that position. For a 4-bit decoder, try `gray = 0011`, which should decode to `binary = 0010`. This input distinguishes the adjacent-bit dependency from a direct dependency on the most significant bit when decoding bit 0.

- **A bit uses the wrong dependency.** Correct its XOR operand and verify the decode. For a counter, sample every rising edge to check the update cadence, all values, and wraparound.
- **All bits match the conversion.** Trace the increment and Gray re-encoding. If the values are right but appear on unexpected edges, [check the output cycle](../clocked-logic/output-flag-timing.md).

**Observed in `TopModule.sv`**, a 4-bit Gray counter that advances every two clocks. The original bit 0 equation XORed `gray_wire[0]` with `bin_out[3]`, yielding `0011` for the example above. The supplied reference fix changed that operand to `bin_out[1]` and kept the existing registers. The submission used combinational prefix XORs and fed back the registered Gray output through the binary increment register. It matched the reference on all 421 graded samples.
