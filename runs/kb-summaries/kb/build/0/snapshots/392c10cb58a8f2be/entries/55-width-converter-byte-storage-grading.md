# Width converter byte storage grading result

This follows entry 54. The submitted 8-to-16-bit TopModule passed all 141 grading samples. Both the submission and reference replaced transparent byte storage with a rising-edge register using nonblocking assignments and active-low asynchronous reset. The submission wrote the register only on the first valid byte of each pair. The reference wrote it on every valid byte.

On the second valid edge, the reference's output assignment reads the previous value of the byte register, which still holds the first byte. The new register value takes effect after that read. The next first-byte edge overwrites it before another output can use it. Idle cycles leave the byte register and pair flag intact in both implementations.

For similar packers, trace the pre-edge values used by nonblocking assignments and check when each stored value is read again. An internal update on the output edge can be harmless when that edge consumes the old value and the next transaction overwrites the new value before using it.
