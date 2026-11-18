# Registering valid in a 24-to-128-bit width converter

TopModule packs accepted 24-bit inputs into a continuous stream of 128-bit output words with the oldest bits first. Its combinational valid_out decoded the counter after it advanced while data_out used the counter value before the edge. A bit-stream scoreboard observed valid_out high on the fifth accepted input while data_out still held its reset value.

Register valid_out on the rising clock edge with asynchronous active-low reset. Use the existing valid_in qualification and pre-edge counts 5, 10, and 15, which also control the data register. This asserts valid_out on the sixth, eleventh, and sixteenth accepted inputs in each group and clears it on the next edge. The counter and data packing needed no changes.

The same Icarus Verilog scoreboard passed 1,119 cycles and 153 output words after the fix, covering continuous valid input, gaps at all three completion boundaries, randomized traffic, and reset with a partial word pending. For similar width converters, verify that the data and valid outputs use the same clock edge and pre-edge condition.
