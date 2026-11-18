# Compare pulse width and period in each divider mode

**Check** the number of input-clock ticks between output rising edges and the number of ticks the output stays high. Trace each divisor and both mode switches, including the frame wrap. When an output comparison is registered, use the pre-edge counter and mode. For a counter starting at zero, an inclusive comparison such as `count <= 3` gives four high ticks.

- **The periods and switch points agree, but a pulse width differs.** Inspect the output comparison in that mode. Correct its threshold and verify both high and low intervals across a complete repeating frame.
- **A period or switch point differs.** Check the period counter's terminal count and whether each mode switch coincides with a period wrap. If the mode changes on the wrong edge, see [Check how a counter mode flag holds and changes](counter-mode-flag.md). Compute the division ratio as input ticks per completed output period over the frame. If the description gives conflicting counts, compare that result with the target ratio and programmed divisors before changing the counters.
- **Both measurements agree.** Check the output immediately after reset assertion and on the first edge after release if the waveform still differs. See [Check which cycle an output flag reports](output-flag-timing.md).

**Observed in `TopModule.sv`**, an 8.7× fractional divider. The stated count of 53 output cycles in 10 input cycles was misleading. The counters scheduled three 8-tick periods followed by seven 9-tick periods, giving ten output periods in 87 ticks.

- In one version, the even-mode shift was `>> 3`, which held the output high for three ticks. Changing only that shift to `>> 2` gave four high ticks in each mode and matched all 2,021 graded samples.
- In an earlier version, the even-mode shift was `>> 1`, which held the output high for six ticks. The reference also used `>> 2`. A submission using `count < (period >> 1)` and deriving the mode from the frame counter matched all 2,021 graded samples for that task. The two predicates agree for divisors 8 and 9 and can differ for other divisors.
