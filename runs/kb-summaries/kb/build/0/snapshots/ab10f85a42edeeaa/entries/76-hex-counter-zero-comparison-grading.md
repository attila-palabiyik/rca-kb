# Grading result for the settable hexadecimal counter zero comparison

In this variant of TopModule, the four-bit internal counter `num` and both outputs were already registered. Outside reset, `number` sampled pre-edge `num`, and `zero` incorrectly tested that same value against `4'd1`. The reference changed only the comparison to `num == 4'd0`.

The submission instead removed the internal count register, exposed the set or increment result on the edge that computed it, and asserted `zero` during reset. Its Icarus simulation passed against those assumptions, but 248 of 273 grading samples differed from the reference.

The reference clears `num`, `number`, and `zero` during asynchronous reset. The first rising edge after release displays zero and asserts the flag, while the internal count increments or loads. A set or rollover becomes visible at the outputs on the following rising edge. This variant complements entry 60, where the original data output was combinational and the reference added the output register.

For similar clocked RTL repairs, trace which pre-edge values each output already samples. When data and status already sample the same state, check the status predicate before changing the pipeline or reset values. Build independent test expectations for reset, the first edge after release, and both edges around a load or rollover.
