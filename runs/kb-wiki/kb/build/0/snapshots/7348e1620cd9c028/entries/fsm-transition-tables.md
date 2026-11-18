# FSM transition tables

When an FSM has a specified transition table, compare the next-state logic against every state and input combination. In a ternary such as `data ? S1 : S0`, the first destination is for `data=1` and the second is for `data=0`. Identical destinations make the transition independent of the input. Check that this matches the table.

In the five-state Moore `TopModule` task with the wrong `S4` exit, `data ? S1 : S1` always sent the machine to `S1`. The table required `S4` to go to `S1` on `1` and `S0` on `0`. Changing the false branch to `S0` was the supplied correct fix. All 261 grading samples matched.

Exercise both exits from the state that asserts the output. In this design, either exit lowers `flag`, so checking the output on the exit edge alone cannot distinguish `S0` from `S1`. A directed simulation can check the destination state on that edge or feed three more `1` samples after the `0` exit and verify that `flag` is still low. A fourth `1` should assert it.

In the six-bit, non-overlapping `TopModule` detector for `011100`, `sf6` reported a failed group and unconditionally advanced to `s1`. This treated the first bit of the next group as matched even when it was `1`. The supplied one-line fix was `nstate = data ? sf1 : s1;` in `sf6`, matching the first-bit check in `idle` and `s6`. The submitted fix combined those three case labels and passed all 1,215 grading samples. The existing Moore output timing and reset behavior already met the requirements of this task.

For a grouped detector, exercise the first bit of a new group after both terminal states. A failed group followed by `111100` should fail again, and a failed group followed by `011100` should match. In both cases the first edge of the new group clears the previous result, so check the result at the end of that group as well. The submitted fix passed a local Icarus Verilog check of all 4,096 ordered pairs of six-bit groups.

For an unreachable output state, see [FSM state encodings](fsm-state-encodings.md). For output decoding and reset behavior, see [FSM output timing and reset](fsm-output-reset.md).
