# Duplicate state encodings in a Verilog FSM

Applies when a state machine holds after a particular transition, or when a Moore output asserts in the wrong state or never asserts even though the next-state logic appears to lead to its output state.

1. Compare the effective encodings of every state named in the current-state `case`. Check the widths of the literals and the state register. A sized literal can truncate before assignment, even if the state register is later widened. If two labels have the same effective value, the first matching case item controls the next transition and either label will satisfy an equality check in the output decode.
2. Trace the first input that should move the machine between the aliased states. In `TopModule.sv`, both `S2` and `S3` were encoded as 2. With `data=1` in `S2`, the next-state expression selected `S3`, but the register stayed at encoding 2. The `S2` case kept matching, so the `S3` branch never advanced the machine to `S4`.
3. If the encoding check explains the stall, compare the reset, transition expressions, and output decode against the spec before changing other logic. In this task the active-low reset, transition expressions, and `S4` output decode matched the spec. Editing the output decode would have missed the cause of the unreachable state.
4. After restoring distinct encodings, drive the machine through the affected path and verify the Moore output from the current state. The local Icarus test covered both input values in each of the five states and reset from `S4`.

Source task: `TopModule.sv`, five-state Moore FSM with an unreachable flag state. Changing only the `S3` encoding from 2 to 3 matched all 261 grading samples. The grader's reference fix made the same encoding change.

## Overlapping 1011 detector

In the `TopModule.sv` detector for `1011`, the same `S2`/`S3` alias prevented even a single isolated match. Start with `1011` and one more sampled bit to check state reachability and the delayed flag. If that passes, `10110111` checks overlap after a full match, and `101011` plus one more bit checks [fallback after a partial match](fsm-next-state-branches.md#overlapping-sequence-detector). The existing fallback branches already retained the appropriate prefixes, and the registered flag already pulsed one clock after the match.

Changing only `S3` from 2 to 3 matched the reference on all 153 grading samples. The local Icarus simulation checked both overlap paths, asynchronous reset, and flag timing for all 4,096 12-bit input streams.

## Six-bit sequence detector

In `TopModule.sv`, the non-overlapping `011100` detector declared `sf6` as `4'd20`. Its low four bits encode decimal 4, the same value as `s4`. After sampling the prefix `0111`, the FSM entered `s4` and the `sf6` comparison asserted `not_match` two bits early. When a failed group reached its sixth bit, the `s4` case took precedence over `sf6`, so the next edge could consume the new group's first bit as if it were the fifth bit of the old group.

The transitions otherwise accounted for all six bits and used the first bit of the next group on exit from either result state. The reference changed only `sf6` to `4'd12`, an unused encoding that fits. The submitted change also used wildcard combinational sensitivity lists and simplified the reset check. It matched all 1,215 grading samples. The local Icarus test checked all 4,096 ordered pairs of six-bit groups in a continuous stream, the result timing after each edge, and asynchronous reset during both result pulses and mid-group.
