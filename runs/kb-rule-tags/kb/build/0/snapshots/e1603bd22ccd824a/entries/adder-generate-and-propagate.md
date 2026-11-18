For an adder using XOR propagation, check that each bit's generate signal is the AND of its operand bits and its propagate signal is their XOR.

Applies to binary adders that compute carries from per-bit generate and propagate signals. In the 4-bit `TopModule` adder, both signals used XOR. The reference fix changed only the generate expression to AND. The submitted fix also expanded the carry equations into gate primitives and matched all 425 grading samples.
