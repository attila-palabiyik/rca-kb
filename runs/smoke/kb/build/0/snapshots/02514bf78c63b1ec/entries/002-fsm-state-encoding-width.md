# Check state encodings at their declared width

When an FSM takes an unexpected transition or asserts an output early, check each state's effective value at the register width. A sized Verilog literal can lose high bits before it is assigned to a parameter. Two names can then refer to the same state, so a `case` takes the first matching branch and a separate output decoder can report the wrong result. Compile with warnings enabled and check that each encoding fits and is unique. If the width is deliberate and a free value exists, use that value for the colliding state.

In the `TopModule` detector for non-overlapping groups of six bits, `sf6 = 4'd20` truncated to `4'd4`, the value of `s4`. Reaching `s4` could assert `not_match` after four samples, and reaching `sf6` could take `s4`'s transition on the next edge. I gave `sf6` the unused encoding `4'd12` and used `always @(*)` for the combinational blocks as requested.

The local Icarus Verilog test reported a pass for all 4,096 ordered pairs of consecutive six-bit groups. It compared both outputs on every sampled bit and between edges, and exercised asynchronous reset mid-group and after each type of result. Testing pairs checked whether an ending state consumed the first bit of the next group correctly. No external grading result was available.
