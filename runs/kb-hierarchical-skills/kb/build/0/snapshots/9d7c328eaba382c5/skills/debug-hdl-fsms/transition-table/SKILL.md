---
name: transition-table
description: Compare each next-state branch in a Verilog or SystemVerilog state machine against a specified transition table.
---

# Check each transition table entry

1. Match every state and input combination to the next-state expression. For `data ? a : b`, compare `a` against the `1` column and `b` against the `0` column. Check both columns even when the operands are identical, since a repeated destination may be valid.
2. Check the outgoing transitions of states that assert an output. For a Moore machine, drive each input value before the active clock edge and check that the output still reflects the current state. After the edge and nonblocking assignments settle, check the destination and its output. If two destinations have the same output, inspect the state in simulation or apply a continuation that distinguishes them.
3. If the state encodings, output decode, and reset already match the specification, limit the edit to the mismatched destination.

In the graded `TopModule.sv` task for a five-state Moore machine, `S4` asserted `flag` correctly but sent both input values to `S1`. Replacing the `0` operand with `S0` matched all 261 grader samples. The local Icarus Verilog test exercised all ten state and input combinations and checked `flag` and the active-low asynchronous reset.
