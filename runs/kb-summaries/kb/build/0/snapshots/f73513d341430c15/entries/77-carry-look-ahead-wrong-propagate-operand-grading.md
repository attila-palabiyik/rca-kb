# Grading result for the 4-bit adder with the wrong propagate operand

In this variant of `TopModule.sv`, `G = A_in & B_in` was already correct. The propagate expression used `P = A_in ^ C_1`, taking the scalar carry-in in place of the four-bit second operand. With `A_in = 0`, `B_in = 1`, and `C_1 = 0`, the original produced zero instead of one. The reference changed only the propagate expression to `P = A_in ^ B_in`.

The submission corrected the propagate operands, used Verilog gate primitives and wire declarations, and expanded the recursive carries into look-ahead equations. Icarus Verilog matched five-bit addition on all 512 binary input combinations. The submission passed all 425 grading samples. The reference retained the original continuous assignments and recursive carries, so the grading result establishes sampled functional agreement. The gate primitives and carry dependencies can be verified by inspecting the submitted RTL.

For similar adder repairs, check which inputs feed propagate and generate before changing the carry logic. Hold carry-in low and vary a single bit of the second operand with the first operand clear to isolate an omitted operand. This complements entries 24 and 25, where the generate operator was the source of the arithmetic bug.
