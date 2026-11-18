# Gray counter encoder shift grading result

In the 4-bit Gray counter TopModule, the binary-to-Gray encoder used `(bin_add_wire >> 2) ^ bin_add_wire`. That produces `0011` for binary 2, whose reflected Gray code is `0010`. The supplied reference changed only the shift from 2 to 1 and retained the original registered decoder, incrementer, and output.

The submitted fix also used the one-bit shift. It computed the decode and increment combinationally from the registered Gray output and used a toggle to enable updates on every second rising edge. Icarus Verilog verified all 16 values, wraparound, hold cycles, and asynchronous reset during counting. The submission matched all 421 grading samples.

For similar RTL bugs, check conversion equations before changing the clocked stages. The Gray encoder XORs the binary word with itself shifted right by one. The decoder uses cumulative XOR from the most significant bit down. Checking binary 2 distinguishes the correct shift from a shift by two, since both produce the same results for binary 0 and 1. A cycle-by-cycle check also covers the first update after reset and subsequent hold cycles.
