# Carry generation and propagation in a binary adder

Use this guide when a binary adder drops a carry from two set operand bits or creates a carry from a single set operand bit with carry-in low.

1. Set carry-in to 0 and isolate a single bit. On the 4-bit adder, `1 + 1` should produce 2 and `1 + 0` should produce 1. If the results are 0 and 3, inspect the generate and propagate expressions at bit 0. The same check at the top bit, `8 + 8`, should set carry-out and produce a zero sum.
2. Compare the intermediate signals with their bit truth table. Two ones generate a carry with `G = A & B`. Exactly one set operand bit propagates carry-in with `P = A ^ B`. If both expressions use XOR, the first case loses its carry and the second creates one. After checking those expressions, trace carry-in through one set operand bit and check that the sum uses the incoming carry for each bit.
3. Check the carry equation separately from its implementation. In this case, the existing recurrence `Cout = G | (P & Cin)` and sum `S = P ^ Cin` already used the correct carries. An explicit look-ahead implementation expands the recurrence into terms in `G`, `P`, and the initial carry. Check gate primitives and wire declarations separately when the specification calls for them. For four-bit operands, exhaust all 512 input combinations and compare the concatenated carry-out and sum to a five-bit arithmetic result.

The source task was the 4-bit carry look-ahead adder in `TopModule.sv`. Its original code used XOR for both `P` and `G`. The reference fix changed only the operator in the `G` assignment to AND. The submitted version also implemented explicit look-ahead with AND, OR, and XOR primitives, as requested. It matched all 425 grading samples and passed a local Icarus Verilog test of all 512 input combinations.

## Propagate XOR uses the wrong input

Use this check when changing one operand leaves the sum unchanged, especially when the other operand and carry-in are zero.

1. Set `A_in = 0`, `C_1 = 0`, and `B_in = 1`. The expected sum is 1 with carry-out 0. All generate bits are zero, so the set bit of `B_in` must reach the sum through `P[0]`. Repeat with `B_in = 4` to check a higher propagate bit.
2. Check the XOR inputs even if the operator is already correct. In this case, `G = A_in & B_in` was correct, and tracing the carry recurrence and sum showed that they consumed the expected intermediate signals. The faulty `P = A_in ^ C_1` omitted `B_in`. Both operands belong in the propagate XOR, and carry-in feeds the carry equations and the bit-zero sum.

In this separate 4-bit carry look-ahead adder task in `TopModule.sv`, the grading reference changed only `P` to `A_in ^ B_in`. The submitted gate-level implementation used the corrected operands and expanded the carry recurrence into parallel look-ahead terms. It matched all 425 grading samples and passed a local Icarus Verilog check of all 512 input combinations.
