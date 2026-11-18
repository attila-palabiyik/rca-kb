# Duplicate state encodings can trap a Verilog FSM

When a Verilog FSM stalls even though its next-state expressions match the transition table, check that every named state has a distinct encoding in the width of the state register. Duplicate values make ordinary `case` items overlap, so the first matching branch takes precedence.

In the five-state Moore `TopModule` task, `S2` and `S3` both encoded decimal 2. The `S2` branch assigned `S3` on a high input, but that preserved the register value and selected the `S2` branch again. The machine could never reach `S4`, where `flag` asserted.

Changing only `S3` to decimal 3 passed all 261 grading samples. A local Icarus Verilog test also covered both inputs from every state, checked that `flag` stayed stable when `data` changed before the clock edge, and verified active-low reset from `S4`.
