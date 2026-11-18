When the pipeline specifies a clocked output stage, register the final result on the active clock edge and clear that register with the pipeline's reset.

Applies when a pipelined datapath drives its output combinationally from intermediate registers even though the output belongs to the next stage. In the 4-bit unsigned `TopModule` multiplier, the reference fix registered the sum of the two partial-product sums with a rising-edge clock and an active-low asynchronous reset. The submitted fix made the same change and matched all 43 grading samples.
