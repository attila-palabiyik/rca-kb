---
name: debug-verilog-adder-carry
description: Diagnose incorrect sums or carry-outs in Verilog adders that use per-bit generate and propagate signals.
---

# Debug Verilog adder carry logic

1. Check the operator and both operands of each per-bit term before changing the carry network. With XOR propagation, the generate signal is `G[i] = A[i] & B[i]` and the propagate signal is `P[i] = A[i] ^ B[i]`. Test a bit with both operands high and no incoming carry to isolate generation. With zero carry-in, set one bit in `B` and hold `A` at zero. The sum should reproduce `B`, which catches a propagate expression that uses the carry-in in place of `B`. Repeat with the single set bit in `A` to check the other operand.
2. Trace the external carry into bit zero, the incoming carry into each sum XOR, and the highest bit's outgoing carry to the carry-out port. If the recurrence is correct, fix the wrong term locally when the existing topology meets the task requirements. If explicit gate primitives and parallel carry look-ahead are required, expand the recurrence into AND product terms and OR them so later carries do not depend on earlier carry outputs. Avoid treating a numerical simulation pass as evidence of a particular topology.
3. For a small adder, exhaustively check the concatenated carry-out and sum against an addition that widens both operands by one bit. Include both values of the external carry.

## Observed results

- In one 4-bit adder task in `TopModule.sv`, both `G` and `P` used XOR. The reference patch changed `G` from XOR to AND. The submitted gate-level implementation with parallel carry equations matched all 425 graded samples and passed an exhaustive 512-case Icarus Verilog simulation.
- In a later `TopModule.sv` task, `G` already used AND, and `P` incorrectly used `A_in ^ C_1`. The reference patch changed only that expression to `A_in ^ B_in`. The submitted implementation also used the requested gate primitives and expanded the carries in parallel. It matched all 425 graded samples and passed all 512 binary input combinations in Icarus Verilog.
