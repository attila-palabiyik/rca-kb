# Check the pattern fields against the shift direction

**Check** that the shift assignment advances each retained sample by one position and inserts the new sample at the end specified by the detector's bit ordering. Trace two successive samples through the assignment, then compare each fixed pattern field with its slice and constant in stream order. Check that the comparisons ignore any don't-care positions.

- **The assignment fails to advance the samples or inserts at the wrong end for the specified bit ordering.** Correct the shift assignment and recheck both fields against the resulting window.
- **The shift produces the intended window, and a slice or constant differs from the pattern or includes don't-care bits.** Correct the comparison. If the checks already sample the intended window on the intended edge, preserve their timing and reset behavior.
- **The shift and comparisons agree with the pattern.** Check whether the reset state or its first shifts can satisfy the comparisons and whether that behavior agrees with the specification.

**Observed in `TopModule.sv`**, a detector for `011XXX110` with an incorrect prefix constant. The shift assignment placed the newest bit at bit 0. Both comparisons sampled the pre-edge window, so the slices `[8:6]` and `[2:0]` already selected the correct fields. Changing the prefix constant from `001` to `011` passed all 237 graded samples. The suffix comparison, registered timing, and all-zero reset were preserved.

**Observed in a separate `TopModule.sv` task**, the same detector used `{a, a_tem[7:0]}` as its shift assignment. This overwrote bit 8 on every edge and left bits 7 through 0 at their reset values. Changing the assignment to `{a_tem[7:0], a}` alone passed all 237 graded samples. The existing field comparisons sampled the pre-edge window and reported a match one rising edge after the final bit entered.
