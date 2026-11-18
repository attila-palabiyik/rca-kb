# Check how a counter mode flag holds and changes

**Check** whether the mode flag reads its own value in a combinational assignment to implement a hold or toggle. Trace the mode used by the datapath on the switching edge and the following edge, including at counter wrap.

- **The combinational flag feeds back, and a registered counter determines the mode.** Decode the mode from that counter. Verify that clocked consumers use the old mode for the terminal tick and the new mode on the following tick.
- **The combinational flag feeds back, and the mode depends on earlier events.** Register the flag with the required reset and use a nonblocking update at each transition. Verify the reset mode and the pre-edge transition conditions.
- **The flag changes on the intended edges.** Continue with [Check the wrap edge in each counter mode](counter-mode-wrap.md).

**Observed in `TopModule.sv`**, an 8.7× fractional divider with a self-referential combinational `div_flag`. The reference fix registered the flag with an asynchronous active-low reset and toggled it when the pre-edge frame count was 23 or 86. The submitted fix decoded `cyc_cnt >= c89` and matched all 2,021 graded samples. Both select the 8-tick mode for frame counts 0 through 23 and the 9-tick mode for counts 24 through 86 under the default parameters. The stated count of 53 output cycles in 10 input cycles was misleading. The verified schedule gives 10 output cycles in 87 input cycles.
