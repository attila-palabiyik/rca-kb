# Preserve explicit reset gating when converting FSM outputs to combinational logic

In the `TopModule` detector for non-overlapping six-bit groups (`011100`), the original output registers decoded `pstate` on the rising edge, so they reported each completed group one cycle late. Moving the decode to a combinational block aligned the outputs with the edge that sampled the sixth bit. My version decoded only `pstate` and relied on the asynchronous state reset to clear the outputs. It passed an Icarus test covering all 64 groups and reset, but the test checked reset after a delay. Grading reported 1 mismatch in 1,215 samples.

The reference also decodes the completed-group states combinationally, and it explicitly drives both outputs low when `rst_n` is low. The failing sample was not identified. In simulation, a state-only decode depends on the state register's nonblocking update reaching the reset state, while the reference output block can respond directly to `rst_n`.

When replacing registered FSM outputs with combinational state decoding, carry over any explicit reset override. Include reset in the output block's sensitivity, either through `always @*` or an explicit list, and exercise reset from a state that asserts an output. Checks that wait for the state reset to settle can miss the difference between these implementations.
