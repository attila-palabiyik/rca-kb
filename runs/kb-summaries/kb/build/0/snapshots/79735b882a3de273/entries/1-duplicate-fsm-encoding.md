# Duplicate state encoding in a Moore FSM

`TopModule` used a clocked state register and a combinational case statement for next-state and output logic. The transition table required `S2` to advance through `S3` to `S4` on high input. Both `S2` and `S3` were encoded as 2, so the transition from `S2` back to that encoding kept selecting the earlier `S2` case item. The machine could never reach `S4`, the only state that asserted `flag`.

Changing only `S3` from 2 to 3 gave every state a distinct encoding. A temporary Icarus Verilog testbench passed all ten state/input transitions, checked that input changes between clock edges did not alter the Moore output, and checked active-low reset from `S4`. The submitted edit matched the reference patch and passed all 261 grading samples.

For an FSM that stalls despite a case statement that matches the transition table, check whether the state constants are distinct and fit the width of the state register.
