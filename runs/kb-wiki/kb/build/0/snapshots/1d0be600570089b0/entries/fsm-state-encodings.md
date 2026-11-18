# FSM state encodings

When an FSM never asserts an output tied to a particular state, check that the named states have distinct encodings at the width of the state register. If two state constants share an encoding, assigning either one stores the same value. A plain Verilog `case` with duplicate values takes the first matching branch.

In the five-state Moore `TopModule` task, `S2` and `S3` both encoded decimal 2. On `data=1`, the `S2` branch assigned `S3`, which stored 2 again. The earlier `S2` case item kept matching, so the machine never took the `S3` transition to `S4`, where `flag` is asserted. Changing `S3` to decimal 3 was sufficient. All 261 grading samples matched the reference after the fix.

## Duplicate encodings in an overlapping detector

In the overlapping `1011` `TopModule` variant, `S2` represented `10` and `S3` represented `101`. Both encoded decimal 2, so the first `S2` case item matched after `101` and the final `1` could never reach `S4`. The submission and supplied fix both changed only `S3` to decimal 3. All 153 grading samples matched.

An Icarus Verilog test checked all 4,096 twelve-bit streams against a four-bit history model. It also checked two overlapping pulses in `10110111` and asynchronous reset while `flag` was high. The [registered flag](fsm-output-reset.md) asserted one rising edge after the last bit of each match. A separate variant with distinct encodings missed `101011` because of a [partial-match transition](fsm-transition-tables.md#preserve-partial-matches-in-overlapping-detectors).

## Check for truncation in sized state literals

In the six-bit, non-overlapping `TopModule` detector for `011100`, the failure terminal `sf6` was declared as `4'd20`. The four-bit literal discarded the high bit of 20, yielding `4'b0100`, the encoding of `s4`. Reaching `s4` after the first four correct bits therefore asserted `not_match` early. Entering `sf6` after a failed group also selected the earlier `s4` transition, which could lose alignment with the next six-bit group.

The supplied fix changed only `sf6` to the unused, representable `4'd12`. The submission made that change and used `always @(*)` for the reset-gated Moore outputs. All 1,215 grading samples matched the reference. An Icarus Verilog test checked outputs on each edge across all 4,096 ordered pairs of six-bit groups and exercised asynchronous reset.

When a terminal flag asserts during a partial match, compare the effective value of its state literal with the encodings of intermediate states. Check the literal's declared width as well as the register width. For a grouped detector, sample intermediate edges and check the next group's result after each terminal state.

For shift-register detectors with predicates sampled in different cycles, see [Shift-register output timing](shift-register-output-timing.md).

For a Moore output that arrives a cycle late or must clear during reset, see [FSM output timing and reset](fsm-output-reset.md).

When states have distinct encodings and a state takes the wrong exit, see [FSM transition tables](fsm-transition-tables.md).
