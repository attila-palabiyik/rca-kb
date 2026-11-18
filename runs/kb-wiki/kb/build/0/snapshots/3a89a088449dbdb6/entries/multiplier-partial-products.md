# Multiplier partial products

When a pipelined shift-and-add multiplier gives wrong products, trace each multiplier bit from its shifted partial product through the registered sums to the output. Each partial product should reach the final sum exactly once. To isolate the paths, drive a nonzero multiplicand with a one-hot multiplier and check the corresponding shifted value after the pipeline delay.

In the 4-bit unsigned pipelined `TopModule` multiplier, `adder_1` summed `temp[2]` twice, duplicating the contribution from `mul_b[2]` and dropping the one from `mul_b[3]`. The submitted and supplied fixes both changed the sum to `temp[2] + temp[3]`. All 43 grading samples matched. A local Icarus Verilog test also passed all 256 input pairs driven on consecutive cycles and checked asynchronous reset between clock edges.

## Check the final sum's clock edge

In a separate 4-bit unsigned pipelined `TopModule` task, all four partial products reached the correct sums, but the combinational final adder exposed the product on the edge that captured the operands. Both the submitted and supplied fixes registered `mul_out <= adder_0 + adder_1` on the rising edge with an active-low asynchronous reset. The final register samples the previous values of `adder_0` and `adder_1`, so each product appears one rising edge after operand capture. All 43 grading samples matched. A local Icarus Verilog test passed all 256 input pairs driven on consecutive cycles and verified reset with a product pending.

Check arithmetic and latency independently. For this two-stage design, compare the output after each rising edge against the product of the operands captured on the preceding rising edge. Drive successive products that differ to expose a cycle offset. Assert and release reset between rising edges while both stages contain data, then check that the output clears on assertion and the pending product never appears.

For another example of checking cycle alignment in registered logic, see [Shift-register output timing](shift-register-output-timing.md).

For per-bit diagnostics in a combinational adder, see [Adder carry generation](adder-carry-generation.md).
