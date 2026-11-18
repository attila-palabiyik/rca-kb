# Duplicate state encodings can trap a Verilog FSM

When a Verilog FSM stalls even though its next-state expressions match the transition table, check that every named state has a distinct encoding in the width of the state register. Duplicate values make ordinary `case` items overlap, so the first matching branch takes precedence.

In the five-state Moore `TopModule` task, `S2` and `S3` both encoded decimal 2. The `S2` branch assigned `S3` on a high input, but that preserved the register value and selected the `S2` branch again. The machine could never reach `S4`, where `flag` asserted.

Changing only `S3` to decimal 3 passed all 261 grading samples. A local Icarus Verilog test also covered both inputs from every state, checked that `flag` stayed stable when `data` changed before the clock edge, and verified active-low reset from `S4`.

The overlapping `1011` detector (`TopModule`) had the same `S2`/`S3` collision. Changing only `S3` from 2 to 3 exactly matched the reference fix and passed all 153 grading samples. The existing transitions already retained the matching suffix after a partial miss or a full match, and the separate `flag` register already gave the requested one-edge delay. A local Icarus Verilog test compared all 4,096 twelve-bit streams against the previous edge's four-bit window and checked asynchronous active-low reset. When an encoding collision makes later transitions unreachable, fix the collision first and test those transitions and the output timing before changing either.

In the `TopModule` detector for non-overlapping six-bit groups (`011100`), the failed-group state `sf6` was written as `4'd20`. The four-bit literal truncates to `4'd4`, which collides with `s4`. A failed group therefore takes the `s4` transition on the next clock edge and loses group alignment. The reference fix changed only `sf6` to the unused `4'd12`. My submission also switched both combinational blocks to wildcard sensitivity and simplified the reset-gated output decode. It matched all 1,215 grading samples, and the one-line reference fix shows that the combinational edits were unnecessary to fix the collision.
