# Check for duplicate state encodings

**Check** the effective numeric encodings used by the state register and its case labels. Evaluate each sized literal at its declared width, then account for any further truncation when assigning it to the state register. Look for two states that share a value and check which case arm takes precedence if their labels also collide.

- **A collision exists.** Compare the affected states' behavior against the specification and trace which case arm handles the shared encoding. If the spec treats them as distinct states, assign unique values that fit in the register. Exercise both input branches from each affected state and check that any downstream Moore output is reachable.
- **The encodings are unique.** Go to [the transition-table check](transition-table.md).

**Observed in `TopModule.sv`** in a five-state Moore FSM. Both `S2` and `S3` were encoded as 2, so entering the `S3` encoding still selected the earlier `S2` case arm. The FSM could never reach `S4`, which the output register samples to assert `flag`. The graded fix changed `S3` to 3 and matched all 261 reference samples. The same collision recurred in an overlapping `1011` detector. Changing only `S3` from 2 to 3 matched the reference patch and all 153 grading samples, with the existing overlap transitions and next-cycle flag timing intact.

**Observed in `TopModule.sv`** in a Moore FSM that checks `011100` in non-overlapping six-bit groups. The failure state `sf6` used `4'd20`, which truncated to `4'd4` and collided with `s4`. Reaching `s4` could assert `not_match` after only four bits, and a failed group reaching `sf6` used the `s4` transition on the next clock. The reference fix only changed `sf6` to the unused `4'd12`. The submitted fix also used wildcard sensitivity lists and simplified the reset condition. It matched all 1,215 reference samples.
