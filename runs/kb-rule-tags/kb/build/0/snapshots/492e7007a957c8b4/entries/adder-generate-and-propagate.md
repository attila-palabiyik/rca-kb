For an adder using XOR propagation, check that each bit's generate signal is the AND of its operand bits and its propagate signal is their XOR.

Applies to binary adders that compute carries from per-bit generate and propagate signals. In the 4-bit `TopModule` adder, both signals used XOR. The reference fix changed only the generate expression to AND. The submitted fix also expanded the carry equations into gate primitives and matched all 425 grading samples.

In another 4-bit `TopModule` adder, the propagate expression XORed `A_in` with the scalar carry-in `C_1`. The reference fix changed only the second operand to `B_in`. The submission made the same operand correction and implemented the expanded carry equations with gate primitives. It matched all 425 grading samples.
