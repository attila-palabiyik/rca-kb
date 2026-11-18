# Grading confirms the multiplier output register fix

The 4-bit unsigned TopModule submission passed all 43 grading samples. The reference made the same functional change as the submission. It registered the final sum on the rising clock edge and cleared the output register on the falling edge of the active-low reset. The partial-product generation and first-stage adders required no change.

For similar pipelined arithmetic bugs, check latency independently of the arithmetic. This result required the product to appear on the rising edge after operand capture. A scoreboard that drives distinct inputs on consecutive cycles and compares each output with the preceding input pair detects the missing register, even when every product value is correct. Assert reset between edges with a product pending to check that reset also flushes the pipeline.
