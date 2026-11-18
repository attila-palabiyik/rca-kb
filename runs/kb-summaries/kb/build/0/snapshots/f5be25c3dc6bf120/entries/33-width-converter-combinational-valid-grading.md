# Grading result for a width converter with combinational output valid

TopModule converts a continuous stream of accepted 24-bit inputs into 128-bit words. The original combinational valid flag asserted after the fifth accepted input while the registered data still held its old value. An Icarus Verilog scoreboard reproduced that mismatch.

The submitted fix passed all 261 grading samples. The reference also changed only the valid block to a rising-edge register with asynchronous active-low reset. Both versions qualify pre-edge counts 5, 10, and 15 with `valid_in`, so the flag and output data update together. The submission and reference differ in literal sizing and expression spelling.

For similar valid-only interfaces, check whether the flag and data use the same pre-edge write condition. Sample both after the edge that accepts the final input and after the preceding edge to detect a flag that leads its data.
