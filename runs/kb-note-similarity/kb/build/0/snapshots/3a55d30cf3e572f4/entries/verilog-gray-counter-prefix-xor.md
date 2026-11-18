# Check the prefix XOR in a Gray-code counter

In the 4-bit Verilog `TopModule` Gray-code counter, the Gray-to-binary decoder combined `gray_wire[0]` with `bin_out[3]`. For Gray `0010`, this produces binary `0010` where the correct result is `0011`. Each binary bit is the XOR of the Gray bits from the most significant bit down through that position. The reference corrected the last assignment to `bin_out[0] = gray_wire[0] ^ bin_out[1]`, using the binary bit computed immediately above it.

The submitted fix expressed each bit as a reduction XOR over its Gray slice, including `bin_out[0] <= ^gray_wire[3:0]`. This allowed nonblocking assignments because every right-hand side read the same Gray value directly. It matched all 421 graded samples. The one-line reference fix shows that the conversion equation alone needed correction. When using nonblocking assignments in a clocked decoder, compute each bit directly from the Gray input so it does not sample the previous cycle's binary bit.

Trace the register feedback before adding a clock divider. Here the decoder and increment registers already formed a two-edge loop, with the output register capturing the encoded increment value. An Icarus Verilog test confirmed the first output increment on the second rising edge after reset, the complete sequence and wraparound, and asynchronous reset during counting.
