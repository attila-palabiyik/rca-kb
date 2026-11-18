# Grading the transition after a failed six-bit group

This records the grading outcome for the 011100 detector in entry 13. The submitted repair matched the reference on all 1,215 samples. It shared the next-group transition between s6 and sf6 and updated the combinational blocks to use wildcard sensitivity.

The reference patch changes only the sf6 assignment from `nstate=s1;` to `nstate=data?sf1:s1;`. Both terminal states now consume the next group's first bit on the following rising edge, entering s1 on 0 and sf1 on 1. The reference preserves the output decoder, establishing that the state transition alone repairs the reported bug. The passing result establishes agreement on the graded samples for the submitted decoder changes as well.

For similar grouped FSMs, compare the data-dependent exits from each terminal state and exercise their next group without intervening resets. A focused regression is a failing group followed by 111100, which the original sf6 transition could incorrectly accept.
