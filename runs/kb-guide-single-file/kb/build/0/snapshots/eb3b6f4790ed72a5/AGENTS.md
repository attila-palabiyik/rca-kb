# Debugging guides

## A Moore FSM stalls before its output state

Use this when the transition table appears correct in the HDL but the output state is unreachable or the machine stalls partway through a sequence.

1. Check that each named state has a distinct encoding that fits in the state register. In an ordinary Verilog `case`, the first matching item executes. If two state constants share a value, only the earlier branch can execute for that value.
2. Trace the path to the output state one clock edge at a time. If the branch formulas, output assignments, and reset already match the specification, changing them will leave an encoding collision in place.
3. Verify both input values from each state, including exits from the output state. Check the Moore output before and after each clock edge to confirm it depends on the registered state.

In `TopModule.sv`, `S2` and `S3` both encoded decimal 2, so a transition to `S3` still selected the `S2` branch and the machine could never reach `S4`. Changing only `S3` to decimal 3 passed all 261 grading samples. A local Icarus Verilog simulation also passed all ten transitions, the Moore output checks, and active-low reset.
