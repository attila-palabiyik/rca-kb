# Check the shift in a binary-to-Gray conversion

**Check** that the most significant Gray bit copies the most significant binary bit and each lower Gray bit XORs adjacent binary bits. For an unsigned binary value `b`, the equation is `b ^ (b >> 1)`. Try `b = 4'b0010`. The expected Gray code is `0011`, while a two-bit right shift produces `0010`.

- **The shift selects the wrong neighbor.** Correct the shift and verify the full code sequence. For a counter with registered feedback, sample every rising edge after reset to check which edges hold the value, which advance it, and when it wraps.
- **The encoded bits match the conversion.** If the next value is wrong, [check the Gray-to-binary decode](gray-to-binary.md) and trace the binary increment. If the value appears on the wrong edge, [check the output cycle](../clocked-logic/pipeline-output-timing.md).

**Observed in `TopModule.sv`**, a 4-bit Gray counter that advances every two clocks. The reference changed only the conversion shift from `>> 2` to `>> 1`. It kept the clocked decode, increment, and output stages, which already provided the required cadence. The submission used the corrected equation with combinational conversion and an every-other-edge enable on the output register. It matched the reference on all 421 graded samples.
