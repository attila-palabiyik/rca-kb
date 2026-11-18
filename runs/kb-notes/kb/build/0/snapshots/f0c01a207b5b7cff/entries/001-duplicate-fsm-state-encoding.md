# Duplicate state encodings in a Verilog FSM

When a case-based state machine stalls or never asserts an output associated with a later state, compare the numeric encodings of its named states. Distinct names can resolve to the same value. If two case items match, the first one runs, so the later state's branch is unreachable.

In the five-state Moore `TopModule` task, `S2` and `S3` both used encoding 2. The `S2` branch's transition to `S3` therefore left the register at encoding 2, and the next clock still used the `S2` branch. Changing only `S3` to encoding 3 matched the reference on all 261 grading samples. An Icarus Verilog simulation also exercised all ten state/input combinations and confirmed that `flag` was high only in `S4` and cleared on active-low reset.
