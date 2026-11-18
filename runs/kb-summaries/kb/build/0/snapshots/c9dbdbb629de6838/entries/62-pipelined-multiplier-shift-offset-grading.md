# Grading result for the pipelined multiplier shift offset

The one-line change in TopModule.sv from `mul_a << (i-1)` to `mul_a << i` matched the published reference patch exactly and passed all 43 grading samples. The two registered stages and asynchronous reset were preserved. The self-authored Icarus Verilog bench also passed all 256 operand pairs streamed on consecutive clocks and a reset asserted between edges with a product pending.

For similar shift-and-add datapaths, trace each multiplier bit to the shift that gives its binary weight. A one-hot multiplier isolates a single term. A continuous operand stream checks that the arithmetic repair preserves the existing input-to-output latency.
