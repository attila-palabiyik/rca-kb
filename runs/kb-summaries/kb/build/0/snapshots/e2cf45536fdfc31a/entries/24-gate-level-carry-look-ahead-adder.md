# Gate-level carry look-ahead adder

The 4-bit `TopModule` used XOR for both the propagate and generate signals. Whenever both operand bits were 1, the generate signal was 0 even though the bit should generate a carry. For example, with both operands equal to 1 and carry-in equal to 0, the supplied logic produced 0 instead of 2. The supplied carry equations also formed a ripple chain through continuous assignments.

The fix uses XOR primitives for propagate and sum, AND primitives for generate and the carry product terms, and OR primitives to combine those terms. Each carry is expanded directly in terms of generate, propagate, and the input carry. The original port order is preserved, and all module signals are wires. The first implementation passed an Icarus Verilog check of all 512 binary input combinations, comparing the concatenated carry-out and sum against 5-bit addition.

For similar combinational adder fixes, verify the generate and propagate definitions separately. A truth-table test confirms arithmetic, while inspecting the carry dependencies confirms the requested look-ahead structure.
