# Traffic light red-state buffer grading

In TopModule, the red-state branch assigned both `p_red` and `p_green` to 1. The output registers copied those buffers one edge later, so the green buffer could assert the green output during red and affect the countdown logic, which uses the green output and its buffer.

The attempted rewrite used the light outputs as one-hot state and reloaded the countdown on the same edge as each light change. It passed a self-written testbench derived from the prose, but the grader reported 220 mismatches in 517 samples. The supplied correct diff changed only `p_green <= 1'b1` to `p_green <= 1'b0` in the red-state branch and removed the trailing timing comment. The reference preserved the idle startup, all-off light reset, output register stage, counter reload conditions, and transition comparison at count 3.

For timing-sensitive RTL bug fixes, trace the defective assignment through the existing registers and apply the narrow correction first. Verify the reproduced defect and check that observable reset and transition timing outside that defect matches the original design. A testbench derived solely from the prose can validate a rewrite while missing the timing used by the reference.
