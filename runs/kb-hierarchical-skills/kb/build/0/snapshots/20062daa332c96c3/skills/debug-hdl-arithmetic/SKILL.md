---
name: debug-hdl-arithmetic
description: Diagnose incorrect carry logic, Gray-code conversion errors, and missing or duplicated terms in Verilog and SystemVerilog arithmetic pipelines.
---

# Debug HDL arithmetic

- When a carry look-ahead adder produces an unexpected carry, [check the per-bit generate and propagate equations](carry-generate-propagate/SKILL.md) before tracing the carry network.
- When a Gray-code counter skips values or produces the wrong sequence, check the [Gray-to-binary XOR chain](gray-to-binary/SKILL.md).
- When a multiplier builds shifted partial products, trace each multiplier bit from its gating expression through the registered sums to the output. In an unsigned shift-and-add multiplier, every bit must contribute its own shift exactly once. Check the operands of each adder for repeated indices and skipped terms.
- To isolate a suspect term, hold the multiplicand at a nonzero value and drive one-hot multiplier values. Each result should equal the multiplicand shifted by the position of the set bit. Check on the output edge implied by the existing pipeline. For small operand widths, drive every pair on consecutive cycles and use a latency-aligned expected value to check both arithmetic and throughput.
- If the error is confined to an adder operand, correct that operand and preserve the register boundaries and reset behavior. Check asynchronous reset between clock edges with a product still in flight.

In the graded 4-bit unsigned `TopModule` multiplier, the second first-stage sum used `temp[2]` twice, doubling the contribution from `mul_b[2]` and dropping `mul_b[3]`. Changing the second operand to `temp[3]` matched all 43 reference samples.
