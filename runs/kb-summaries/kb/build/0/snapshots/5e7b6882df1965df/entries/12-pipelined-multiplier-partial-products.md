# Duplicated partial product in a pipelined multiplier

The unsigned 4-bit multiplier in `TopModule.sv` generated four shifted partial products, one per bit of `mul_b`. The first pipeline stage summed the lower pair correctly, but the upper adder used `temp[2] + temp[2]`, doubling the contribution from bit 2 and omitting bit 3. Changing the upper sum to `temp[2] + temp[3]` matched the reference fix exactly. The submission passed all 43 grading samples.

An independent Icarus Verilog test passed all 256 operand pairs streamed on successive clocks. It checked that each product appeared on the rising edge after operand capture and that asserting reset between edges cleared both the output and the pending product.

For similar shift-and-add datapaths, trace each multiplier bit through the adder tree and check that each partial product appears once. Drive a nonzero multiplicand with one-hot multipliers to isolate missing or duplicated terms. For a pipelined design, compare consecutive outputs against the corresponding earlier inputs.
