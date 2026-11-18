# Sample the pre-edge count for a one-cycle-delayed zero flag

The Verilog `TopModule` decimal up/down counter decoded its current count combinationally. This asserted `zero` in the cycle that `number` became 0 and as soon as reset was released while `number` was still 0. The task specified a pulse in the following cycle and an asynchronous active-low reset that cleared both outputs.

The submitted fix used `zero <= (number == 4'd0)` in the rising-edge block that updated `number`, with both outputs cleared in its reset branch. All 289 grading samples matched. The reference used a separate rising-edge block with the same reset and comparison. Both versions sample the pre-edge count through nonblocking assignments.

For delayed flags, test consecutive edges around the event. Counting up through `9 → 0 → 1` produced `zero = 0` at 0 and `zero = 1` at 1. Counting down through `1 → 0 → 9` produced the pulse at 9. Also check reset release between edges. In this design, `zero` stayed low until the first rising edge after release, then asserted because the sampled reset count was 0.
