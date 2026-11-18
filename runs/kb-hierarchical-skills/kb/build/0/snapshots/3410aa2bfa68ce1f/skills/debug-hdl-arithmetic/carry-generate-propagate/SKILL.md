---
name: carry-generate-propagate
description: Diagnose swapped or duplicated generate and propagate expressions in Verilog and SystemVerilog carry look-ahead adders.
---

# Check carry generate and propagate signals

1. For an adder that uses XOR propagation, check each bit against `G[i] = A[i] & B[i]` and `P[i] = A[i] ^ B[i]`. Check both operands even when the gate operator is correct. If you can probe `P`, hold `A` and `B` fixed and toggle carry-in. `P` should stay constant. Confirm that the sum XOR uses the incoming carry for that bit.
2. With carry-in low and all other operand bits clear, set the same bit in both operands to check carry generation. Set that bit in just one operand to check that it leaves the outgoing carry low. For a carry propagation check, set external carry-in high and make the operands complementary through the bits under test.
3. If the carry recurrence already matches the specification, fix the incorrect generate or propagate expression locally. When the task requires primitive gates or expanded look-ahead equations, check those structural requirements separately from arithmetic simulation. For a small combinational adder, exhaustively compare the concatenated carry-out and sum against a widened `A + B + carry_in` result.

In the graded 4-bit `TopModule.sv` adder, both `G` and `P` were assigned XOR. The reference fix changed only `G` to AND. The submitted implementation also used gate primitives and expanded the carry equations. It matched all 425 grader samples and passed a local Icarus Verilog check of all 512 binary input combinations.

In a separate graded 4-bit `TopModule.sv` adder, `P` XORed `A_in` with the one-bit carry-in `C_1`. The reference fix changed the second operand to `B_in`. The submitted fix also used primitive gates and expanded look-ahead equations to meet the requested structure. It matched all 425 grader samples and passed all 512 binary input combinations in Icarus Verilog.
