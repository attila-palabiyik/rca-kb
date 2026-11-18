---
name: debug-verilog-fsm
description: Diagnose Verilog or SystemVerilog FSMs that stall or skip states by checking state encodings and exercising the specified transition table.
---

# Debug Verilog FSMs

1. When the transition branches match the specification but a state is unreachable, compare the numeric values of the state constants at the state register's width. Two labels with the same encoding make the later plain `case` branch unreachable. Trace the reset-to-target path to find where the machine stalls or takes the wrong branch.
2. If an encoding collision explains the failure, give the affected state a distinct representable value. Preserve the specified transition, output, and reset behavior. For designs with intentional state aliases, check the specification before changing encodings.
3. For a small FSM, use the specification to drive every state/input pair, including self-loops and both exits from the output-asserting state. Check the state as well as the output during simulation, since several Moore states can have identical outputs. Change the input before a clock edge and check that the output still corresponds to the current state. Exercise reset from a state with a different output when possible.

## Observed result

In the five-state `TopModule.sv` Moore FSM, `S2` and `S3` both encoded decimal 2. The `S2` branch therefore kept selecting the same encoded state when it attempted to advance to `S3`. Changing only the value of `S3` to decimal 3 fixed the failure. Icarus Verilog passed all ten state/input pairs, Moore output checks, and active-low reset checks. The grader reported 261 of 261 samples matched the reference.
