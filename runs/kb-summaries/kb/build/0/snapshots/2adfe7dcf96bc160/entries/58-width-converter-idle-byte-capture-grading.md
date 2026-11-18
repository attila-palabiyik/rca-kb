# Grading result for the idle-byte capture fix

This follows entry 57. The submitted 8-to-16-bit TopModule matched all 141 grading samples. The original byte register wrote on invalid cycles. The reference fixed the enable by changing it from !valid_in to valid_in, so it writes on both accepted bytes. The submission wrote only on the first accepted byte by using valid_in && !flag.

On the second accepted edge, the output register reads the pre-edge value of the byte register because the assignments are nonblocking. Both implementations therefore pack the first byte into the upper half. In the reference, the second byte stored on that edge is overwritten by the next pair's first byte before any output can use it. Idle cycles preserve the buffered byte in both implementations.

For a clocked valid-only packer with an inverted enable, check which edge consumes the stored value and which edge next replaces it. If those reads and writes follow this pattern, fixing the polarity alone is sufficient.
