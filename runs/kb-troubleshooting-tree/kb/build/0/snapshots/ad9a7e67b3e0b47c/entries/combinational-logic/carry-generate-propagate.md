# Check the carry-generate and carry-propagate equations

**Check** the operator and both source bits in each carry term. For an adder that uses XOR propagation, `G[i] = A[i] & B[i]` creates a carry when both operand bits are 1, and `P[i] = A[i] ^ B[i]` passes the incoming carry when the bits differ. Drive `A = B = 1` at the bit under test with zero incoming carry to isolate generation. Then try both orders of unequal operand bits with both incoming carry values to check propagation.

- **A term uses the wrong operator or source.** Correct that term and verify both the sum and carry with the same inputs. Check that the correction applies at every bit position.
- **Both terms match the equations.** Trace which carry feeds each sum and verify the final carry-out against the highest bit position.

**Observed in `TopModule.sv`**, a 4-bit carry look-ahead adder. Both `G` and `P` used XOR, so with operands `4'b1000` and `4'b1000` and zero carry-in, the most significant bit failed to generate a carry. The supplied reference fix changed only `G` to `A_in & B_in`. The submission also expressed the expanded carry equations with gate primitives and matched the reference on all 425 graded samples.

**Observed in a separate `TopModule.sv` task**, also a 4-bit carry look-ahead adder. The propagate equation used XOR with `C_1` in place of `B_in`, so checking the operator alone would have missed the bug. The supplied reference fix changed only `P` to `A_in ^ B_in`. The submission corrected the source and implemented the expanded carry equations with gate primitives. It matched the reference on all 425 graded samples.
