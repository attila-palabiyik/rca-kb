# Compare pulse width and period in each divider mode

**Check** the number of input-clock ticks between output rising edges and the number of ticks the output stays high. Trace each divisor and both mode switches, including the frame wrap. When an output comparison is registered, use the pre-edge counter and mode. For a counter starting at zero, an inclusive comparison such as `count <= 3` gives four high ticks.

- **The periods and switch points agree, but a pulse width differs.** Inspect the output comparison in that mode. Correct its threshold and verify both high and low intervals across a complete repeating frame.
- **A period or switch point differs.** Check the period counter's terminal count and whether each mode switch coincides with a period wrap. Compare the number of completed periods in one frame with the stated division ratio.
- **Both measurements agree.** Check the output immediately after reset assertion and on the first edge after release if the waveform still differs. See [Check which cycle an output flag reports](output-flag-timing.md).

**Observed in `TopModule.sv`**, an 8.7× fractional divider. The stated count of 53 output cycles in 10 input cycles was misleading. The existing counters already scheduled three 8-tick periods followed by seven 9-tick periods, giving ten output periods in 87 ticks. The original even-mode predicate `count <= ((div_e >> 1) + 1)` held the output high for six ticks. The reference changed the shift to `>> 2`, which gave four high ticks in each mode with the default divisors. The submission used `count < (period >> 1)` and derived the mode from the frame counter. It matched all 2,021 graded samples. The two threshold formulas agree for divisors 8 and 9 and can differ for other divisors.
