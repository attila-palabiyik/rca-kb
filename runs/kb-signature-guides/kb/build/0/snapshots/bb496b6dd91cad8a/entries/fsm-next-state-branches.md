# Next-state branches that disagree with the transition table

Use this guide when an FSM reaches the expected state but exits to the wrong destination for one input value. A Moore output can still look correct on the exit edge if both destinations decode to the same output.

1. Compare each input column in the failing state's transition-table row with its next-state expression. For `data ? A : B`, check `A` against the `1` column and `B` against the `0` column. Repeated destinations are valid only when the table specifies the same result for both inputs.
2. If the expressions name the expected destinations, check whether those states have distinct numeric encodings. If the state sequence is correct but the output is wrong, check the output decode and its timing. In this task the encodings were distinct, the active-low asynchronous reset returned the FSM to `S0`, and the Moore decode asserted `flag` in `S4`. The mismatch was in the `S4` next-state expression.
3. Drive the FSM to the affected state separately for each input value. Check the destination after the sampling edge. When two destinations yield the same output, inspect the current state in simulation or drive a sequence that makes their outputs diverge. Here both `S0` and `S1` drove `flag` low, so checking `flag` immediately after leaving `S4` could miss the bug.

Source task involved `TopModule.sv`, a five-state Moore FSM. Its `S4` expression was `data ? S1 : S1`. Changing the `0` branch to `S0` matched the reference fix and passed all 261 grading samples. The local Icarus simulation checked all ten transitions, Moore output timing, and asynchronous reset from `S4`.
