---
name: debug-verilog-adder-carry
description: Diagnose incorrect sums or carry-outs in Verilog adders that use per-bit generate and propagate signals.
---

# Debug Verilog adder carry logic

1. Check the per-bit terms before changing the carry network. With XOR propagation, the generate signal is `G[i] = A[i] & B[i]` and the propagate signal is `P[i] = A[i] ^ B[i]`. Test a bit with both operands high and no incoming carry to isolate generation. Test a bit with exactly one operand high with both values of the incoming carry to distinguish propagation from generation.
2. Trace the external carry into bit zero, the incoming carry into each sum XOR, and the highest bit's outgoing carry to the carry-out port. If the recurrence is correct, fix the wrong term locally when the existing topology meets the task requirements. If explicit gate primitives and parallel carry look-ahead are required, expand the recurrence into AND product terms and OR them so later carries do not depend on earlier carry outputs. Avoid treating a numerical simulation pass as evidence of a particular topology.
3. For a small adder, exhaustively check the concatenated carry-out and sum against an addition that widens both operands by one bit. Include both values of the external carry.

## Observed result

In the 4-bit carry look-ahead adder task in `TopModule.sv`, both `G` and `P` used XOR. The supplied correct patch changed only `G` from XOR to AND and kept the original carry recurrence and continuous assignments. The submission also used AND, OR, and XOR primitives and expanded the carry recurrence into parallel terms to meet the requested structure. It matched all 425 graded samples and passed all 512 binary input combinations in a local Icarus Verilog test.
