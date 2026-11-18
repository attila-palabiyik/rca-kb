# Trace partial products and register stages in a pipelined multiplier

In the 4-bit unsigned pipelined multiplier `TopModule`, the second registered adder summed `temp[2] + temp[2]`, so bit 2 of the multiplier contributed twice and bit 3 contributed zero. Replacing the second operand with `temp[3]` matched the reference on all 43 graded samples. The fix preserved the two register stages and their active-low asynchronous reset.

When a shift-and-add multiplier gives wrong products, trace each multiplier bit's partial product through the adder tree and check that it reaches the output once. With a nonzero multiplicand, a multiplier operand with only one bit set isolates its partial product. Check the result at the output edge implied by the existing registers. A local Icarus Verilog test passed all 256 input pairs presented on consecutive cycles and checked the output timing and reset.

In a separate `TopModule` task, both partial-product sums were correct and registered, but the final sum was combinational. This produced the right product on the input sampling edge, one cycle earlier than the reference. Changing only the final sum to a rising-edge register with a nonblocking assignment and an active-low asynchronous reset matched all 43 graded samples.

A test that changes operands on consecutive cycles can catch this timing bug even when every product is arithmetically correct. For this two-stage pipeline, the Icarus test compared the output after each rising edge with the operands sampled on the previous edge. It passed all 256 operand pairs and confirmed that reset asserted between edges immediately cleared the output and discarded the in-flight product.
