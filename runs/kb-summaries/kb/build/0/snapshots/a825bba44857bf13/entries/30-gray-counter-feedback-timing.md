# Two-clock Gray counter feedback timing

The 4-bit TopModule converted a Gray feedback wire to binary in one clocked stage and incremented it in a second. Blocking assignments let the increment stage observe the current decode depending on simulator event order. The original Icarus simulation advanced on edge 3, when the output should have held its value. The least-significant decoded bit also omitted two of the Gray bits.

The fix uses nonblocking assignments for the sampled decode and computes each binary bit as the cumulative XOR from the Gray MSB through that bit. The existing increment stage naturally wraps at four bits. Its asynchronous reset also drives the combinational Gray feedback wire to zero.

The same independent Icarus test passed after the fix. It checked every edge across two full wraps, one-bit transitions, asynchronous reset between edges, and restart timing. The first increment appeared on the second rising edge after reset release.

For similar RTL tasks, trace the registered stages in the feedback loop separately from the output register. Verify the hold cycles and first update after reset as well as the sequence values.
