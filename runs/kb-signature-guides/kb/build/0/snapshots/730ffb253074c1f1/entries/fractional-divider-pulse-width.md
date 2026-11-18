# Pulse width in a fractional clock divider

Applies when a divider alternates integer periods and the output frequency looks right, but a high or low pulse has the wrong width in one mode.

1. Count rising-edge intervals and high cycles separately in each mode, including the periods on either side of a mode switch. Check that the switch and frame wrap coincide with the period counter wrapping. If these checks pass, focus on the output comparison. A count of output cycles over a whole frame can pass even when a falling edge is misplaced.
2. Evaluate the output comparison at each count using the value before the rising input edge if the output is registered with a nonblocking assignment. For a counter starting at zero, `count <= threshold` includes `threshold + 1` high cycles when the threshold is in range. Check the shift amount and the comparison operator separately.
3. If the worked example conflicts with the stated divide ratio, compute the ratio from the configured frame and the number of complete periods it contains. Use that to check the period schedule before changing either counter.

## 8.7× divider in `TopModule.sv`

The period counter and switching logic already produced three 8-cycle periods in the first 24 input cycles and seven 9-cycle periods in the remaining 63. This gave ten output periods per 87 input cycles, matching the stated 8.7× ratio despite the contradictory worked example. The 9-cycle branch used `count <= ((period >> 2) + 1)` and was already high for counts 0 through 3.

Two versions had different shifts in the 8-cycle branch. With `count <= ((period >> 1) + 1)`, the output stayed high for counts 0 through 5. With `count <= ((period >> 3) + 1)`, it stayed high for counts 0 through 2. In both versions, the reference used `>> 2`, giving four high cycles in both modes.

The submissions used `count < (period >> 1)` in both branches and sized the counters from the parameters. Each matched all 2,021 grading samples. The comparison expressions agree for periods 8 and 9 and can differ for other settings. For example, at period 12 the reference expression gives five high cycles and the submitted expression gives six. Local Icarus checks exercised wider counters under the submitted pulse-width rule. The grading result confirms agreement for the sampled behavior.
