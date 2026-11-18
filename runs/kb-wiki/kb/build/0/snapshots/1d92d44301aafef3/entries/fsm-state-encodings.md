# FSM state encodings

When an FSM never asserts an output tied to a particular state, check that the named states have distinct encodings at the width of the state register. If two state constants share an encoding, assigning either one stores the same value. A plain Verilog `case` with duplicate values takes the first matching branch.

In the five-state Moore `TopModule` task, `S2` and `S3` both encoded decimal 2. On `data=1`, the `S2` branch assigned `S3`, which stored 2 again. The earlier `S2` case item kept matching, so the machine never took the `S3` transition to `S4`, where `flag` is asserted. Changing `S3` to decimal 3 was sufficient. All 261 grading samples matched the reference after the fix.

For shift-register detectors with predicates sampled in different cycles, see [Shift-register output timing](shift-register-output-timing.md).

For a Moore output that arrives a cycle late or must clear during reset, see [FSM output timing and reset](fsm-output-reset.md).
