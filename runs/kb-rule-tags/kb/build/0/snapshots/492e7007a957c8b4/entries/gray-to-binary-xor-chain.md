When decoding reflected Gray code to binary, copy the most significant bit and XOR each lower Gray bit with the binary bit immediately above it.

Applies to Gray-to-binary conversion in a counter feedback path. In the 4-bit `TopModule` Gray counter, the least significant bit used `gray_wire[0] ^ bin_out[3]`. The reference fix changed the binary operand to `bin_out[1]` and kept the original clocked stages. The submitted fix corrected the same dependency and used combinational conversion with an every-other-clock enable. It matched all 421 grading samples.
