# Preserve explicit reset when decoding FSM outputs

In the six-bit `TopModule` detector for `011100`, the original clocked output block read the old FSM state and reported the result one clock after the sixth bit. Decoding the current state in `always @(*)` corrected the group timing. The attempted fix relied on the asynchronous reset of the state register to clear `match` and `not_match`. It passed an Icarus test covering all 4,096 pairs of six-bit groups and settled reset behavior, but one of 1,215 grading samples differed from the reference.

The reference also checks `rst_n` directly in the combinational output block and clears both outputs when reset is asserted. This lets reset trigger output evaluation even while the state register's nonblocking reset assignment is pending. Grading did not identify the differing sample, so its exact timing is unknown.

When changing registered FSM outputs to combinational decoding, preserve any explicit reset override in the new block. With `always @(*)`, reading `rst_n` in the reset branch includes it in the sensitivity list. Exercise reset while each result output is high and check the output during reset assertion as well as after the state settles. A check delayed by a full simulation time unit can miss the difference between direct reset handling and clearing through the state register.
