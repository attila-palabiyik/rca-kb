# Check both conversion equations in a Gray-code counter

In the 4-bit Verilog `TopModule` Gray-code counter, the Gray-to-binary decoder combined `gray_wire[0]` with `bin_out[3]`. For Gray `0010`, this produces binary `0010` where the correct result is `0011`. Each binary bit is the XOR of the Gray bits from the most significant bit down through that position. The reference corrected the last assignment to `bin_out[0] = gray_wire[0] ^ bin_out[1]`, using the binary bit computed immediately above it.

The submitted fix expressed each bit as a reduction XOR over its Gray slice, including `bin_out[0] <= ^gray_wire[3:0]`. This allowed nonblocking assignments because every right-hand side read the same Gray value directly. It matched all 421 graded samples. The one-line reference fix shows that the conversion equation alone needed correction. When using nonblocking assignments in a clocked decoder, compute each bit directly from the Gray input so it does not sample the previous cycle's binary bit.

Trace the register feedback before adding a clock divider. Here the decoder and increment registers already formed a two-edge loop, with the output register capturing the encoded increment value. An Icarus Verilog test confirmed the first output increment on the second rising edge after reset, the complete sequence and wraparound, and asynchronous reset during counting.

In a separate 4-bit `TopModule` Gray-counter task, the decoder already used the correct prefix XOR and the encoder shifted by two bits. The reference changed only the shift from `>> 2` to `>> 1` in `(bin_add_wire >> 1) ^ bin_add_wire`. With the two-bit shift, binary `0010` encodes as `0010`, making the transition from `0001` flip two bits. The one-bit shift encodes binary `0010` as `0011`.

The submitted fix corrected the shift and expressed the decoder with nonblocking prefix XORs so both clocked stages read pre-edge values. All 421 graded samples matched. The reference used the existing assignments and changed only the shift. Check the first few encoded values as well as the two-edge update cadence and wraparound, since a wrong shift can still map all 16 binary values to distinct outputs.

## Missing output register

In a third 4-bit `TopModule` Gray-counter task, both conversion equations were correct. The original output exposed the encoded increment register combinationally. The reference changed only the output logic from a combinational assignment to a rising-edge register with active-low asynchronous reset and added comments. The output register samples the pre-edge encoded increment value. The decoder still takes its feedback from that encoded value directly, so the new output register changes when the sequence is visible without adding a stage to the feedback loop.

The submitted fix instead used combinational Gray-to-binary conversion, increment, and re-encoding, and a resettable enable that updated the output on every second rising edge. All 421 graded samples matched the reference. The Icarus test verified that the first edge after reset release holds zero, the second produces one, all 16 values repeat in order, and a mid-count asynchronous reset restarts that timing. The first test run had two transposed pairs in its packed expected sequence. Writing out the ordered values before packing them exposed the test error.

When a counter has correct arithmetic but advances on the wrong edge, trace both the feedback path and the path to the output. Check the first two edges after reset as well as steady-state cadence. A missing output register can affect the initial timing even when the feedback loop already has the intended period.
