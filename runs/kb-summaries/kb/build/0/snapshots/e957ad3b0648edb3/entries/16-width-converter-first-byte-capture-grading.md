# Grading result for the 8-to-16-bit width converter

The submitted TopModule matched all 141 reference samples. The reference swapped the two branches of the register's conditional assignment, so `data_r` captures on every `valid_in` cycle and holds during idle cycles. The submission captures only when `valid_in && !flag`, the first byte of each pair.

On the second valid edge, the nonblocking assignment to `data_out` reads the previous `data_r`. The reference's simultaneous capture of the second byte affects only internal state. The next first byte overwrites that state before another output uses it.

For similar pipelined packers, trace when each register is read and overwritten. A simplified write enable can preserve output behavior when the value it changes is overwritten before its next observable use.
