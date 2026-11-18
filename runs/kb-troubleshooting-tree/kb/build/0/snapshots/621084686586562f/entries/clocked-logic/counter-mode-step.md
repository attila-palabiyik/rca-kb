# Check the step taken by each counter mode

**Check** the next count from an interior value in each mode. For a decimal up/down counter, starting from 5 gives 6 in up mode and 4 in down mode. This exercises the ordinary arithmetic in both branches.

- **A mode takes the wrong step.** Correct that branch's arithmetic. Verify one ordinary step in each mode, then verify both wrap transitions.
- **Both modes take the expected step.** If the count fails at a boundary, check the terminal comparison and reload value for that mode. If only the output flag fails, [check which cycle the flag reports](output-flag-timing.md).

**Observed in `TopModule.sv`**, a decimal up/down counter. Both ordinary branches subtracted one, while the wrap transitions already matched the specification. The reference changed the up branch to `number + 1'd1`. The submitted fix used `number + 4'd1` and matched all 289 graded samples. The existing registered `zero` comparison also matched those samples. This was a separate bug from the decimal counter example in the output flag timing entry.
