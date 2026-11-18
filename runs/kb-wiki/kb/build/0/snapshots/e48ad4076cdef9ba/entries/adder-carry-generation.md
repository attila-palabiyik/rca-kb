# Adder carry generation

When an adder produces incorrect sums or carries, check both the operators and the operands of the per-bit generate and propagate signals. For an XOR-propagate adder, `G[i] = A[i] & B[i]` and `P[i] = A[i] ^ B[i]`. The outgoing carry is `G[i] | (P[i] & carry_in)`, and the sum is `P[i] ^ carry_in`. With carry-in low, operand bits `11` must generate a carry and `01` must leave the carry low. With carry-in high, `01` must propagate the carry.

## Check the generate operator

In one 4-bit adder `TopModule` task, the original code used XOR for both `G` and `P`, so it missed a carry for `1 + 1` and produced a spurious carry for `1 + 0` with carry-in low. The supplied fix changed only the generate assignment to `assign G = A_in & B_in;`, retaining the original carry recurrence and continuous assignments. The submitted gate-level look-ahead implementation matched all 425 grading samples and passed all 512 binary input combinations in Icarus Verilog.

## Check both propagate operands

In a separate 4-bit adder `TopModule` task, `G` already used AND, but `P` used `A_in ^ C_1`. With `A_in = 0` and `C_1 = 0`, the original circuit gives zero even when `B_in = 1`. The supplied fix changed only the propagate assignment to `assign P = A_in ^ B_in;`, preserving the carry recurrence and continuous assignments. Holding `A_in` and `C_1` fixed while driving a one-hot value on `B_in` checks that every operand bit reaches its corresponding propagate bit.

The submission also implemented the requested gate-level look-ahead with `and`, `or`, and `xor` primitives and expanded every carry in terms of generate, propagate, and the original carry-in. It matched all 425 grading samples and passed all 512 binary input combinations in Icarus Verilog against the five-bit arithmetic sum. These comparisons verify output behavior. Inspect primitive usage and carry dependencies in the source to verify the requested structure.

For examples of tracing individual arithmetic terms and isolating incorrect bit weights, see [Multiplier partial products](multiplier-partial-products.md#check-the-shift-for-each-multiplier-bit).

For checking a cumulative XOR dependency with a directed input, see [Gray code conversion](gray-code-conversion.md).

For verifying arithmetic built from decoded truth-table rows, see [Active-low decoder outputs](active-low-decoder-outputs.md).
