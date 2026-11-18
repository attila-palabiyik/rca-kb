# Decimal counter delayed zero flag grading

All 289 graded samples matched the reference for TopModule's decimal up/down counter. The reference changed the combinational zero decode to a rising-edge register with an asynchronous active-low clear. Its explicit conditional and the submitted nonblocking comparison both sample whether the count was zero immediately before the rising edge. The reference kept the original count logic.

For RTL tasks that specify a flag in the cycle after a state is reached, check the two edges around that state. In this counter, the edge that enters zero leaves the flag low, and the edge that leaves zero raises it. Since reset also sets the count to zero, releasing reset leaves the flag clear until the first rising edge, which samples the reset count and raises the flag.
