When a status flag must report a register value in the next cycle, register the comparison against the pre-edge value and reset the flag explicitly to its specified value.

Applies to status flags whose specified latency is one clock after the observed register reaches a value. In the `TopModule` decimal up/down counter, the original combinational zero flag asserted as soon as `number` became zero and could assert on reset release before a clock edge. Registering `number == 4'd0` on the rising edge with an active-low asynchronous reset that cleared `zero` matched all 289 reference samples.
