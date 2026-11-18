# Check the carry-generate and carry-propagate equations

**Check** each carry term against its role in the specified equations. For an adder that uses XOR propagation, `G = A & B` creates a carry when both operand bits are 1, and `P = A ^ B` passes the incoming carry when the bits differ. Drive `A = B = 1` with zero carry-in to isolate generation, then drive unequal operand bits with both carry-in values to check propagation.

- **A term uses the wrong operator.** Correct that term and verify both the sum and carry with the same inputs. Check that the correction applies at every bit position.
- **Both terms match the equations.** Trace which carry feeds each sum and verify the final carry-out against the highest bit position.

**Observed in `TopModule.sv`**, a 4-bit carry look-ahead adder. Both `G` and `P` used XOR, so with operands `4'b1000` and `4'b1000` and zero carry-in, the most significant bit failed to generate a carry. The supplied reference fix changed only `G` to `A_in & B_in`. The submission also expressed the expanded carry equations with gate primitives and matched the reference on all 425 graded samples.
