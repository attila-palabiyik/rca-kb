Check that each state constant fits its literal width and remains distinct at the state register width when debugging a case-based FSM.

Applies to Verilog/SystemVerilog FSMs with explicit state constants. In `TopModule`, `S2` and `S3` both encoded `2`, so the `S2` case arm won and `S4` was unreachable from reset. Changing only `S3` to `3` matched all 261 reference samples. The same one-line fix matched all 153 reference samples in the overlapping `1011` detector, which registers its flag one clock after a match.

In the `TopModule` detector for `011100`, the four-bit literal `4'd20` truncated to `4'd4`, giving the failure-completion state `sf6` the same encoding as `s4`. The reference fix changed only `sf6` to `4'd12`. The submitted fix also used wildcard sensitivity lists and simplified the equivalent reset condition, and it matched all 1215 reference samples.
