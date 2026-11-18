---
name: debug-verilog-fsm
description: Diagnose wrong transitions and unreachable states in Verilog or SystemVerilog FSMs by checking the transition table and state encodings.
---

# Debug Verilog FSMs

1. Compare each next-state expression with both entries in its transition-table row. In `data ? A : B`, `A` is the destination for `1` and `B` is the destination for `0`. Identical destinations can be intentional, so check the row before changing either arm. For a Moore FSM, compare the output decode separately with the specified output for the current state.
2. When the transition branches match the specification but a state is unreachable, compare the numeric values of the state constants at the state register's width. Two labels with the same encoding make the later plain `case` branch unreachable. Trace the reset-to-target path to find where the machine stalls. Check for intentional state aliases before assigning a distinct representable value.
3. For a small FSM, use the specification to drive every state/input pair, including self-loops and both exits from the output-asserting state. Check the state as well as the output during simulation, since several Moore states can have identical outputs. Change the input before a clock edge and check that the output still corresponds to the current state. Exercise reset from a state with a different output when possible.

## Observed results

In the five-state `TopModule.sv` Moore FSM, `S2` and `S3` both encoded decimal 2. The `S2` branch therefore kept selecting the same encoded state when it attempted to advance to `S3`. Changing only the value of `S3` to decimal 3 fixed the failure. Icarus Verilog passed all ten state/input pairs, Moore output checks, and active-low reset checks. The grader reported 261 of 261 samples matched the reference.

In a separate five-state `TopModule.sv` task, the `S4` branch used `data ? S1 : S1`. Changing the `0` destination to `S0` matched the table. Icarus Verilog verified all ten state/input pairs, Moore output timing, and active-low reset from `S4`. The grader reported 261 of 261 samples matched the reference with this one-line fix.
