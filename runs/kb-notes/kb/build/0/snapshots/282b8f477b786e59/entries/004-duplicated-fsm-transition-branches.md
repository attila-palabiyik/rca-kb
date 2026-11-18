# Check both branches of conditional FSM transitions

When debugging a Verilog FSM against a transition table, compare each arm of `input_bit ? next_on_one : next_on_zero` with its corresponding column. Identical arms are valid only when both input values lead to the same state. A directed simulation should visit each state and exercise both values, including exits from a state that asserts the output.

In the five-state Moore `TopModule` task, the original `S4` branch used `data ? S1 : S1`, so a zero incorrectly restarted at `S1` instead of returning to `S0`. Changing only the false arm to `S0` matched all 261 grading samples. The Icarus test passed all ten state/input combinations, checked that `flag` depended on the current state, and checked active-low reset from `S4`. No alternate fix was attempted.
