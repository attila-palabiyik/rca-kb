# Check the wrap edge in each counter mode

**Check** the count immediately before and after the wrap edge in each mode. Use the last legal count in that direction as the pre-edge value. For a decimal up/down counter, the edge should take 9 to 0 in up mode and 0 to 9 in down mode.

- **The count takes another ordinary step at the boundary or wraps early.** Compare the wrap condition with the last legal pre-edge count. With nonblocking assignments, the condition reads the count before the edge updates it.
- **The count wraps on the right edge but lands on the wrong value.** Check the reload value for that mode.
- **Both wrap transitions match.** If an interior count is wrong, [check the step taken by each counter mode](counter-mode-step.md). If only the flag differs, [check which cycle the flag reports](output-flag-timing.md).

**Observed in `TopModule.sv`**, a decimal up/down counter with a late up-mode wrap. The comparison against 10 let the counter advance from 9 to 10 for one cycle. The reference changed the comparison to 9. The submitted fix used `4'd9` for the comparison and `4'd0` for the reload and matched all 289 graded samples.
