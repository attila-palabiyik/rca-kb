# Check for duplicate state encodings

**Check** the numeric encodings used by the state register and its case labels. Look for two specified states that share a value.

- **A collision exists.** Compare the affected states' behavior against the specification and trace which case arm handles the shared encoding. If the spec treats them as distinct states, assign unique values that fit in the register. Exercise both input branches from each affected state and check that any downstream Moore output is reachable.
- **The encodings are unique.** Compare the next-state case arms against the transition table, then trace which states assert each Moore output.

**Observed in `TopModule.sv`** in a five-state Moore FSM. Both `S2` and `S3` were encoded as 2, so entering the `S3` encoding still selected the earlier `S2` case arm. The FSM could never take the transition from `S3` to `S4` that asserts `flag`. The graded fix changed `S3` to 3 and matched all 261 reference samples.
