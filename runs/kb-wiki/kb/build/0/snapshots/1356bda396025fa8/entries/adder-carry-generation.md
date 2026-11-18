# Adder carry generation

When an adder produces incorrect carries, check the per-bit generate and propagate signals before tracing the carry network. For an XOR-propagate adder, `G[i] = A[i] & B[i]` and `P[i] = A[i] ^ B[i]`. The outgoing carry is `G[i] | (P[i] & carry_in)`, and the sum is `P[i] ^ carry_in`. With carry-in low, operand bits `11` must generate a carry and `01` must leave the carry low. With carry-in high, `01` must propagate the carry. These cases isolate a duplicated or swapped operator.

In the 4-bit carry adder `TopModule`, the original code used XOR for both `G` and `P`, so it missed a carry for `1 + 1` and produced a spurious carry for `1 + 0` with carry-in low. The supplied fix changed only the generate assignment to `assign G = A_in & B_in;`, retaining the original carry recurrence and continuous assignments.

The submitted fix also addressed the requested gate-level look-ahead structure. It used `and`, `or`, and `xor` primitives and expanded each carry in terms of generate, propagate, and the original carry-in. All 425 grading samples matched, and a local Icarus Verilog test checked all 512 binary input combinations against the five-bit arithmetic sum. Both checks establish output behavior for the cases tested. Verify primitive usage and carry dependencies from the source when the task specifies a circuit structure.

For examples of tracing individual arithmetic terms and isolating incorrect bit weights, see [Multiplier partial products](multiplier-partial-products.md#check-the-shift-for-each-multiplier-bit).

For checking a cumulative XOR dependency with a directed input, see [Gray code conversion](gray-code-conversion.md).
