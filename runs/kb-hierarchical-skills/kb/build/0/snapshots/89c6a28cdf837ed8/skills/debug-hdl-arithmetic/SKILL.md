---
name: debug-hdl-arithmetic
description: Diagnose incorrect carry logic, decoder-based arithmetic, Gray-code conversion errors, and arithmetic pipeline bugs involving partial products or output timing in Verilog and SystemVerilog.
---

# Debug HDL arithmetic

- When a carry look-ahead adder produces an unexpected carry, [check the per-bit generate and propagate equations](carry-generate-propagate/SKILL.md) before tracing the carry network.
- When arithmetic outputs are built from decoder lines, [check the address mapping, output polarity, and minterms](active-low-decoder/SKILL.md).
- When a Gray-code counter skips values or produces the wrong sequence, [check the Gray-to-binary XOR chain and the binary-to-Gray shift](gray-to-binary/SKILL.md).
- When a multiplier builds shifted partial products, trace each multiplier bit from its gating expression through the registered sums to the output. For a zero-based unsigned multiplier, bit `i` contributes `mul_a << i`, so bit 0 contributes the unshifted multiplicand. Watch for offsets such as `i-1`, and check the operands of each adder for repeated indices and skipped terms.
- To isolate a suspect term, hold the multiplicand at a nonzero value and drive one-hot multiplier values. Each result should equal the multiplicand shifted by the position of the set bit. Check on the output edge implied by the existing pipeline. For small operand widths, drive every pair on consecutive cycles and use a latency-aligned expected value to check both arithmetic and throughput.
- If the error is confined to a shift or an adder operand, correct that expression and preserve the register boundaries and reset behavior. Check asynchronous reset between clock edges with a product still in flight.
- If every partial product is present but the result arrives early, [check the final arithmetic stage against the required output edge](../debug-hdl-fsms/registered-output-timing/SKILL.md#arithmetic-pipelines).

In the graded 4-bit unsigned `TopModule` multiplier, the second first-stage sum used `temp[2]` twice, doubling the contribution from `mul_b[2]` and dropping `mul_b[3]`. Changing the second operand to `temp[3]` matched all 43 reference samples.

In a separate graded 4-bit unsigned `TopModule` multiplier, `mul_b[i]` gated a partial product shifted by `i-1`. Changing the shift to `i` matched all 43 reference samples. An Icarus Verilog simulation also verified all 256 unsigned operand pairs on consecutive cycles, with each product appearing one rising edge after its operands were sampled. Asserting reset between clock edges cleared the output and discarded a product in flight.
