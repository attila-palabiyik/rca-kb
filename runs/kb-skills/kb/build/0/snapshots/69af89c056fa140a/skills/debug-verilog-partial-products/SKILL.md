---
name: debug-verilog-partial-products
description: Diagnose wrong products in Verilog or SystemVerilog multipliers built from shifted partial products and registered sums.
---

# Debug Verilog partial products

1. For an unsigned shift-and-add multiplier, check that multiplier bit `i` selects the multiplicand shifted left by `i` bits. Check both endpoints of any shift expression with a loop-index offset. Bit 0 must select the unshifted multiplicand. Follow the terms through the adder stages and check that each reaches the output exactly once. Inspect repeated indices for a companion term that is never used.
2. Use a nonzero multiplicand and drive each one-hot multiplier value on consecutive clocks. Each expected result is the multiplicand shifted by the selected bit index. This isolates incorrect weights and omitted or duplicated terms. Check results at the output edge dictated by the existing registers, then exercise combined bits to check the sum.
3. Correct the expression or operand where the trace first departs from the expected weight. Preserve the pipeline registers and reset logic when the bug is confined to the arithmetic.

## Observed results

- In one 4-bit unsigned pipelined multiplier task in `TopModule.sv`, the upper-pair adder used `temp[2] + temp[2]`. This counted bit 2 twice and omitted bit 3. Changing the second operand to `temp[3]` matched the reference patch and passed all 43 graded samples. A local Icarus simulation also passed all 256 input pairs streamed on consecutive clocks and checked asynchronous reset.
- In another 4-bit unsigned pipelined multiplier task in `TopModule.sv`, the partial-product expression shifted by `i-1`, which gave bit 0 a shift of `-1` and assigned the other bits one position too low. Changing the shift to `i` matched the reference patch and passed all 43 graded samples. Icarus also passed the one-hot cases, all 256 input pairs streamed on consecutive clocks, and an asynchronous reset with a product pending.
