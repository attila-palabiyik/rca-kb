---
name: transition-table
description: Check next-state branches in Verilog and SystemVerilog against a transition table or rules for consecutive input groups.
---

# Check each transition table entry

1. Match every state and input combination to the next-state expression. For `data ? a : b`, compare `a` against the `1` column and `b` against the `0` column. Check both columns even when the operands are identical, since a repeated destination may be valid.
2. Check the outgoing transitions of states that assert an output. For a Moore machine, drive each input value before the active clock edge and check that the output still reflects the current state. After the edge and nonblocking assignments settle, check the destination and its output. If two destinations have the same output, inspect the state in simulation or apply a continuation that distinguishes them.
3. For fixed-size, nonoverlapping groups, determine whether the clock edge leaving a result state also samples the first bit of the next group. If it does, check both first-bit values after each result. Include a failed group followed by a group whose first bit is wrong and whose remaining bits match the target. Such a group exposes an exit that assumes its first bit matched.
4. If the state encodings, output decode, and reset already match the specification, limit the behavioral edit to the mismatched transition.

In the graded `TopModule.sv` task for a five-state Moore machine, `S4` asserted `flag` correctly but sent both input values to `S1`. Replacing the `0` operand with `S0` matched all 261 grader samples. The local Icarus Verilog test exercised all ten state and input combinations and checked `flag` and the active-low asynchronous reset.

In the graded `TopModule.sv` detector for nonoverlapping `011100` groups, `sf6` unconditionally entered `s1`, the state reached after sampling a correct first bit. The reference fix made that exit `nstate = data ? sf1 : s1`, matching the exit from the success state. With the original exit, a failing group followed by `111100` would produce a false match. The submitted fix also used wildcard combinational blocks and matched all 1,215 grader samples. Local Icarus Verilog verification covered all 4,096 ordered pairs of six-bit groups, output timing, and asynchronous reset.
