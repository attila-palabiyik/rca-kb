# Check the pattern fields against the shift direction

**Check** each fixed pattern field against the slice and comparison constant in the detector. Use the shift assignment to locate the oldest and newest bits, then compare each field in stream order. Check that the comparison ignores any don't-care positions.

- **A slice or constant differs from the pattern, or the comparison includes don't-care bits.** Correct the comparison. If the checks already sample the intended window on the intended edge, preserve their timing and reset behavior.
- **All comparisons agree with the pattern.** Check whether the reset state or its first shifts can satisfy the comparisons and whether that behavior agrees with the specification.

**Observed in `TopModule.sv`**, a detector for `011XXX110` with an incorrect prefix constant. The shift assignment placed the newest bit at bit 0. Both comparisons sampled the pre-edge window, so the slices `[8:6]` and `[2:0]` already selected the correct fields. Changing the prefix constant from `001` to `011` passed all 237 graded samples. The suffix comparison, registered timing, and all-zero reset were preserved.
