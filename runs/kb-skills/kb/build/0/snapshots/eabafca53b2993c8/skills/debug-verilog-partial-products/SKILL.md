---
name: debug-verilog-partial-products
description: Diagnose wrong products in Verilog or SystemVerilog multipliers built from shifted partial products and registered sums.
---

# Debug Verilog partial products

1. For an unsigned shift-and-add multiplier, map each multiplier bit to its shifted partial product. Follow those terms through the adder stages and check that each reaches the output exactly once. Inspect repeated indices for a companion term that is never used.
2. Use a nonzero multiplicand and drive each one-hot multiplier value on consecutive clocks. Each expected result is the multiplicand shifted by the selected bit index. This isolates omitted and duplicated terms. Check results at the output edge dictated by the existing registers, then exercise combined bits to check the sum.
3. When the operand trace identifies a single wrong index, correct that operand in its existing register assignment. Avoid moving registers or changing reset logic to compensate for an arithmetic mismatch.

## Observed result

In the 4-bit unsigned pipelined multiplier task in `TopModule.sv`, the upper-pair adder used `temp[2] + temp[2]`. This counted bit 2 twice and omitted bit 3. Changing the second operand to `temp[3]` matched the reference patch and passed all 43 graded samples. A local Icarus simulation also passed all 256 input pairs streamed on consecutive clocks and checked asynchronous reset.
