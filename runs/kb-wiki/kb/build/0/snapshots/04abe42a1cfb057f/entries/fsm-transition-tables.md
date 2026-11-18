# FSM transition tables

When an FSM has a specified transition table, compare the next-state logic against every state and input combination. In a ternary such as `data ? S1 : S0`, the first destination is for `data=1` and the second is for `data=0`. Identical destinations make the transition independent of the input. Check that this matches the table.

In the five-state Moore `TopModule` task with the wrong `S4` exit, `data ? S1 : S1` always sent the machine to `S1`. The table required `S4` to go to `S1` on `1` and `S0` on `0`. Changing the false branch to `S0` was the supplied correct fix. All 261 grading samples matched.

Exercise both exits from the state that asserts the output. In this design, either exit lowers `flag`, so checking the output on the exit edge alone cannot distinguish `S0` from `S1`. A directed simulation can check the destination state on that edge or feed three more `1` samples after the `0` exit and verify that `flag` is still low. A fourth `1` should assert it.

In the six-bit, non-overlapping `TopModule` detector for `011100`, `sf6` reported a failed group and unconditionally advanced to `s1`. This treated the first bit of the next group as matched even when it was `1`. The supplied one-line fix was `nstate = data ? sf1 : s1;` in `sf6`, matching the first-bit check in `idle` and `s6`. The submitted fix combined those three case labels and passed all 1,215 grading samples. The existing Moore output timing and reset behavior already met the requirements of this task.

For a grouped detector, exercise the first bit of a new group after both terminal states. A failed group followed by `111100` should fail again, and a failed group followed by `011100` should match. In both cases the first edge of the new group clears the previous result, so check the result at the end of that group as well. The submitted fix passed a local Icarus Verilog check of all 4,096 ordered pairs of six-bit groups.

If a terminal transition is already correct in the source but the detector loses group alignment, check for a [truncated state literal](fsm-state-encodings.md#check-for-truncation-in-sized-state-literals).

## Timer-driven exits with registered outputs

In an earlier pedestrian traffic light `TopModule` variant, the supplied correct fix changed two destinations under `cnt == 3`. Red exits to green and green exits to yellow. Yellow already exited to red. The fix retained the idle reset state, registered light buffers, and countdown reload logic.

The submission implemented the requested color order with a new one-hot FSM. It set red during reset and reloaded the timer on the same edge as the light change. Local Icarus checks passed against those timing assumptions, but 220 of 517 grading samples differed from the reference. The supplied fix leaves all lights low during reset. Tracing an ordinary phase boundary in that fix gives the internal state change at displayed count 2, the light buffer change at 1, the visible light change at 0, and the timer reload on the following edge.

When diagnosing a timer-driven FSM, check each destination independently of the transition threshold. Trace the current state, light buffer, visible outputs, and timer across the boundary before editing any pipeline stage. A local test that checks only the rewritten timing assumptions can pass while missing observable changes to reset and phase boundaries. See [FSM output timing and reset](fsm-output-reset.md) for a detector whose task did require changing its output timing.

For an unreachable output state, see [FSM state encodings](fsm-state-encodings.md). For output decoding and reset behavior, see [FSM output timing and reset](fsm-output-reset.md).

## Check reload polarity at the visible output edge

In a later pedestrian traffic light `TopModule` variant, all three state destinations were already correct. The supplied fix changed the green reload condition from `green && p_green` to `!green && p_green` and removed the stale timing comment. The yellow and red reload conditions already used the same polarity. The old green condition skipped the entry edge and then reloaded 60 on every steady green edge without a qualifying pedestrian request. After a cap to 10, it could also reload 60 on the next steady green edge.

With the corrected predicate and a normal red-to-green transition, the internal state changes to green as the displayed count reaches 2. The green buffer rises as the count reaches 1. On the following edge, the timer samples the pre-edge values `green=0` and `p_green=1`, while the visible green output samples the buffer. That edge shows green and 60 together. On the next edge, a pending request can cap 60 to 10. With green and its buffer both high, ordinary countdown resumes once the count is 10 or less.

The submission replaced the pipeline with a direct state decode and asserted red during asynchronous reset. Its Icarus checks passed for the prose timing requirements. Grading reported 220 mismatches in 517 samples. The supplied fix kept the idle reset state, all visible lights low during reset, and the original registered stages. The report gave only the aggregate mismatch count, so the individual mismatched samples are unknown. See [FSM output timing and reset](fsm-output-reset.md) for the reset and output timing distinction.

For a reload driven by a buffered output, compare its condition with the other phase reloads and trace the pre-edge buffer and output values. Check the first visible cycle, the next steady cycle, and the cycle after a request caps the timer. These samples distinguish a missed entry pulse, repeated reloads, and a cap that gets overwritten.
