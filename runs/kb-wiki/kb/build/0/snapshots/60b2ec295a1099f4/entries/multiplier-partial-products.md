# Multiplier partial products

When a pipelined shift-and-add multiplier gives wrong products, trace each multiplier bit from its shifted partial product through the registered sums to the output. Each partial product should reach the final sum exactly once. To isolate the paths, drive a nonzero multiplicand with a one-hot multiplier and check the corresponding shifted value after the pipeline delay.

In the 4-bit unsigned pipelined `TopModule` multiplier, `adder_1` summed `temp[2]` twice, duplicating the contribution from `mul_b[2]` and dropping the one from `mul_b[3]`. The submitted and supplied fixes both changed the sum to `temp[2] + temp[3]`. All 43 grading samples matched. A local Icarus Verilog test also passed all 256 input pairs driven on consecutive cycles and checked asynchronous reset between clock edges.

For this two-stage pipeline, compare the output after each rising edge with the operands captured on the preceding rising edge. Drive successive products that differ so a cycle offset is visible. Assert reset between edges while the pipeline contains data, then check that the output clears immediately and that no pending product appears after reset is released.

For another example of checking cycle alignment in registered logic, see [Shift-register output timing](shift-register-output-timing.md).

For per-bit diagnostics in a combinational adder, see [Adder carry generation](adder-carry-generation.md).
