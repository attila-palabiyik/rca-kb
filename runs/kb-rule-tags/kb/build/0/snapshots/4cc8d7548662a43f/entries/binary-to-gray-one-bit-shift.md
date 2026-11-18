When encoding an unsigned binary value as reflected Gray code, XOR it with a copy of itself shifted right by one bit.

Applies to binary-to-Gray conversion in counter feedback paths. In the 4-bit `TopModule` Gray counter, the encoder shifted the incremented binary value right by two bits. The reference fix changed only the shift distance from two to one and kept the existing clocked stages. The submitted fix used the same one-bit shift with combinational conversion and an every-other-clock enable, and matched all 421 grading samples.
