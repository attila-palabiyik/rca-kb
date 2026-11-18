# Next-state branches that disagree with the transition table

Use this guide when an FSM reaches the expected state but exits to the wrong destination for one input value. A Moore output can still look correct on the exit edge if both destinations decode to the same output.

1. Compare each input column in the failing state's transition-table row with its next-state expression. For `data ? A : B`, check `A` against the `1` column and `B` against the `0` column. Repeated destinations are valid only when the table specifies the same result for both inputs.
2. If the expressions name the expected destinations, check whether those states have distinct numeric encodings. If the state sequence is correct but the output is wrong, check the output decode and its timing. In this task the encodings were distinct, the active-low asynchronous reset returned the FSM to `S0`, and the Moore decode asserted `flag` in `S4`. The mismatch was in the `S4` next-state expression.
3. Drive the FSM to the affected state separately for each input value. Check the destination after the sampling edge. When two destinations yield the same output, inspect the current state in simulation or drive a sequence that makes their outputs diverge. Here both `S0` and `S1` drove `flag` low, so checking `flag` immediately after leaving `S4` could miss the bug.
4. For grouped input, trace which bit each terminal state's outgoing edge consumes. If that edge samples the first bit of a new group, compare the outgoing transitions after reset, success, and failure. Exercise those paths in a continuous stream. Resetting before each group can hide a wrong transition out of a terminal state.

Source task involved `TopModule.sv`, a five-state Moore FSM. Its `S4` expression was `data ? S1 : S1`. Changing the `0` branch to `S0` matched the reference fix and passed all 261 grading samples. The local Icarus simulation checked all ten transitions, Moore output timing, and asynchronous reset from `S4`.

A later `TopModule.sv` task used a six-bit Moore detector for `011100`. The failure terminal state `sf6` always went to `s1`, treating the next group's first bit as `0`. A failed group followed by `111100` could therefore produce a false match. The state encodings were distinct, and the original output decode already asserted a result on the sixth edge with both outputs cleared during reset. The reference changed only the `sf6` transition to `data ? sf1 : s1`. The submitted fix shared that transition across `idle`, `s6`, and `sf6`, used wildcard sensitivity lists, and passed all 1,215 grading samples. Local Icarus simulation checked all 4,096 ordered pairs of groups in a continuous stream and asynchronous reset during a result pulse and mid-group.

## Overlapping sequence detector

1. Label each state with the pattern prefix it represents. For each input bit, append it to that prefix and find the longest suffix that is also a pattern prefix. Use that prefix's state as the destination. Check the transitions after both a partial mismatch and a complete match.
2. In the `TopModule.sv` detector for `1011`, the transitions out of the completed-match state `S4` already preserved the applicable suffixes. The example stream `10110111` exercises overlap after a complete match and bypasses the faulty branch. The bug occurred when `S3` (prefix `101`) consumed `0`. The resulting `1010` ends in `10`, so its destination is `S2`. Drive `101011` followed by one more bit to exercise that branch and observe the match.
3. Check the flag on the edge that samples the last bit and on the following edge. The existing registered comparison reads the pre-edge state and generates the required one-cycle pulse on the following edge. The active-low asynchronous reset clears the flag.

Changing only the `S3` zero branch from `S0` to `S2` matched the reference and passed all 153 grading samples. Local Icarus simulation verified the directed streams and compared the flag against the preceding four sampled bits for all 4,096 12-bit streams, with one extra bit per stream to expose any match at the end.

## Traffic light controller with a countdown

In the traffic light controller's `TopModule.sv`, the required cycle was red → green → yellow → red. Start with a request-free run and check each destination when the countdown triggers a transition. In the original FSM, the `cnt == 3` branches sent red to yellow and green to red. The supplied reference changed those destinations to green and yellow, respectively. Yellow already returned to red.

For an FSM with registered outputs, trace the internal state, intermediate registers, outputs, and timer reload on separate edges. In the reference, an edge that sees `cnt == 3` updates the internal state and decrements the counter to 2. The next edge updates the light buffer at count 1. The following edge updates the visible light at count 0. The next edge reloads the counter. A test that checks only the sequence of light colors misses these offsets.

The submitted rewrite switched the light and reloaded the timer together at count 1 and drove red immediately on reset. Its Icarus tests passed for the rewritten timing, including normal durations and request thresholds, but 220 of 517 grading samples differed from the reference. The reference kept the existing reset behavior, countdown, light registers, and pedestrian-request logic. Fix the verified destination branches first, then test the original and patched waveforms around reset, phase changes, and requests to see which observable changes follow from the corrected state sequence.

Another traffic light task had the correct transition table and a broken green timer reload. See [Timer reload on a registered output transition](timer-reload-on-output-transition.md).
