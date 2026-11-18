# Check the polarity of a phase-entry timer reload

**Check** which values the reload condition samples on the edge that asserts the visible phase output. When the output copies a buffered bit on that edge, entry has a pre-edge visible value of 0 and a buffered value of 1. Check the condition again on the next edge, when both values are 1. Compare the same two cases with the reload guards for other phases.

- **The guard misses entry or also matches a steady phase.** Correct the edge detection. With any higher-priority reload conditions inactive, check the last count of the outgoing phase, the initial count on entry, and the first decrement in the new phase.
- **The guard matches entry only.** If the visible phase still changes on the wrong count, [trace the register stages and transition trigger](transition-output-timing.md).

**Observed in `TopModule.sv`**, a traffic-light FSM with correct red, green, and yellow destinations and a wrong green reload guard. On the edge that asserted green, `green` was still 0 and `p_green` was 1 before the assignments took effect. The original `green && p_green` missed that edge, allowing the timer to fall from 1 to 0. With no pedestrian request, it then reloaded 60 on every edge while both bits were high, preventing the timer from reaching the next transition. The graded fix used `!green && p_green`, matching the red and yellow entry guards. It kept the output pipeline, count-3 state transition trigger, and original reset behavior, and removed the stale timing comment.

The submitted rewrite removed the pipeline and drove red during reset. Its tests passed against the prose timing, but 220 of 517 samples differed from the grading reference. The aggregate does not attribute mismatches to individual differences.
