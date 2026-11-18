# Fractional divider duty cycle

When debugging a fractional divider, check the period schedule and pulse widths separately. Trace the pre-edge counter value used by the registered output. When the counter starts at zero and increments on every sample until wrap, `count <= H - 1` holds the output high for `H` samples when `H` fits within the period.

In two 8.7× fractional divider `TopModule` tasks, the existing schedule produced three 8-cycle periods and seven 9-cycle periods per 87 input cycles. Compute this from the frame parameters: `c89 = 24` gives `24 / 8 = 3` periods before the switch, and `M_N - c89 = 63` gives `63 / 9 = 7` periods after it. That gives 10 output cycles per 87 input cycles and resolves the conflicting count in the prompt. For parameter overrides, check that both segments contain a whole number of periods so the mode switch and frame wrap occur when the period counter returns to zero.

The even-period comparison was `clk_cnt <= ((div_e >> 1) + 1)` in one variant and `clk_cnt <= ((div_e >> 3) + 1)` in the other. At `div_e = 8`, the first gives six high cycles and the second gives three. A test that counts only rising edges misses both bugs. Each reference fixed only the even-period comparison by setting the shift to `>> 2`. Both modes then hold the output high at counts 0 through 3, giving a 4/4 high/low split for period 8 and a 4/5 split for period 9.

Both submissions used `clk_cnt < (period >> 1)`, derived counter widths from the parameters, and selected the period from the frame count. Each matched all 2,021 grading samples. The submitted and reference comparisons agree at periods 8 and 9 and can differ for other periods. For period 10, they give five and four high cycles, respectively. Local Icarus checks on the second submission verified the submitted waveform at periods 17 and 18, checked frames using only one of those periods, and exercised asynchronous reset while the output was high. Those checks used expectations for the submitted half-period rule.

Check both the rising-to-rising interval and the rising-to-falling interval through a complete frame. Include the period switch, frame wrap, and reset while the output is high. For tracing other registered outputs that sample the pre-edge counter, see [Shift-register output timing](shift-register-output-timing.md).

## Align period selection with the frame counter

In another 8.7× divider `TopModule` task, `div_flag` read itself in an `always @(*)` block and inverted itself at `c89 - 1` or `M_N - 1`. That feedback had no clock edge to control when the mode changed. The supplied fix made `div_flag` a positive-edge register with an active-low asynchronous reset to zero and a nonblocking update. When the pre-edge frame count is 23 or 86, the old mode drives the period counter and output for that edge. After the edge, the mode changes alongside the frame count advancing to 24 or wrapping to zero.

The submission decoded `div_flag` as `cyc_cnt >= c89` and sized the counters from the parameters. It kept the original pulse-width comparisons and matched all 2,021 grading samples. Local Icarus runs checked the 87-cycle default frame, a 141-cycle frame using periods 17 and 18, frames with only one active segment, and asynchronous reset during a high pulse. The one-segment runs exercised the submission’s decode. The supplied toggle resets to the first mode and does not generally cover a skipped segment.

When a mode bit changes at a zero-based boundary, trace which mode the counters and output consume on the terminal edge and on the following edge. For a zero-based FIFO address whose wrap bit changes alongside the address, see [FIFO pointer clocking](fifo-pointer-clocking.md#check-that-the-wrap-bit-toggles-with-the-address).
