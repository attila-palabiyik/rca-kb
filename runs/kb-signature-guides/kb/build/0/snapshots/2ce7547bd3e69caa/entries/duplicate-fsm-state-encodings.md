# Duplicate state encodings in a Verilog FSM

Applies when a state machine holds after a particular transition, or when a Moore output never asserts even though the next-state logic appears to lead to its output state.

1. Compare the numeric encodings of every state named in the current-state `case`. If two labels have the same value, the state register cannot distinguish them and an earlier matching case item takes precedence over a later one.
2. Trace the first input that should move the machine between the aliased states. In `TopModule.sv`, both `S2` and `S3` were encoded as 2. With `data=1` in `S2`, the next-state expression selected `S3`, but the register stayed at encoding 2. The `S2` case kept matching, so the `S3` branch never advanced the machine to `S4`.
3. If the encoding check explains the stall, compare the reset, transition expressions, and output decode against the spec before changing other logic. In this task the active-low reset, transition expressions, and `S4` output decode matched the spec. Editing the output decode would have missed the cause of the unreachable state.
4. After restoring distinct encodings, drive the machine through the affected path and verify the Moore output from the current state. The local Icarus test covered both input values in each of the five states and reset from `S4`.

Source task: `TopModule.sv`, five-state Moore FSM with an unreachable flag state. Changing only the `S3` encoding from 2 to 3 matched all 261 grading samples. The grader's reference fix made the same encoding change.
