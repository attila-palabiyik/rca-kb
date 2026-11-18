# Combinational feedback in a counter-controlled mode flag

Applies when a divider fails to switch periods at a programmed count, or the period counter begins using the new terminal count before it has finished the current period.

1. Inspect the mode flag's assignment. A combinational assignment of the form `flag = boundary ? ~flag : flag` asks the flag to invert itself continuously while the boundary is true. It has no stable value in that branch. If the design calls for one toggle per boundary, update the flag in an edge-triggered block with a nonblocking assignment and initialize it in reset.
2. Trace the frame counter, the period counter, and the mode together at both the inner boundary and frame wrap. When the rollover test uses the pre-edge frame count, a boundary at elapsed count `N` is tested as `frame_count == N - 1`. On that edge the period counter still uses the old mode for its terminal-count comparison.
3. If the frame count uniquely determines the mode, a direct decode can replace the flag. Check that both mode segments contain whole output periods and that the decode changes when the frame counter advances, so the last edge of each segment still uses the old period. Check the first edge after reset as well as the two boundaries.

## 8.7× divider in `TopModule.sv`

The reference fix moved the self-inverting `div_flag` assignment into a rising-edge block with active-low asynchronous reset. It toggled on the edges that consumed frame counts 23 and 86. The submitted implementation decoded the mode directly from `cyc_cnt < c89`, selecting three 8-clock periods followed by seven 9-clock periods. It matched all 2,021 grading samples.

The worked example's cycle counts conflicted with the stated ratio. The parameters instead gave ten output periods in 87 input clocks. Both original output comparisons already gave four high clocks per period at the default settings, so the reference fix left them in place. The submission sized the counters from the parameters and used half the period rounded down for the high time. A local Icarus test exercised wider parameters under that rule. The grading result establishes agreement for the sampled behavior, and the two pulse-width formulas can differ for other periods.
