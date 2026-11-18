# Grading result for the fractional divider phase register

The submitted TopModule matched the reference on all 2,021 grading samples. The reference's entire fix was to register `div_flag` on the rising edge of `clk_in`, clear it asynchronously when `rst` goes low, and use a nonblocking assignment to toggle it when the pre-edge frame count is `c89 - 1` or `M_N - 1`. The original combinational block fed the flag back into its own assignment. Clocked storage lets the period counter finish the current period on the same edge that changes the flag for the next period.

The reference explicitly assigns `div_flag` to itself on other edges. The submission holds its value by omitting that assignment in the clocked block and additionally derives the counter widths from the parameters. The reference retains the original widths and pulse-width comparisons. The submitted implementation passed a separate local simulation with a 130-cycle frame and periods of 18 and 19. The grading result establishes agreement for the sampled cases only.

For similar divider bugs, check whether a self-referential selector needs clocked storage, then trace the pre-edge phase and period counters through each switch. Verify waveform timing and reset as well as the average division ratio.
