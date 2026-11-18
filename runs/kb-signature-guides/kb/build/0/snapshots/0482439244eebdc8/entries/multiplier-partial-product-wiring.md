# Partial-product shifts and wiring in a multiplier

Use this guide when a shift-and-add multiplier produces incorrect values at the expected pipeline latency, especially when the error depends on which bits of one operand are set.

1. Hold the multiplicand at 1 and drive one-hot values on the multiplier operand. Compare each result with its corresponding power of two after the declared pipeline latency. Back-to-back vectors distinguish a value error from comparing the output against the wrong input cycle. In a pipeline with registered partial sums and a registered final sum, the output after a rising edge corresponds to the inputs sampled on the preceding rising edge.
2. If bit 0 contributes zero and every higher bit contributes half its expected value, inspect the generator for an off-by-one shift. Multiplier bit `i` has weight `2^i`, so it should select the multiplicand shifted left by `i` in the full partial-product width. With `mul_a = 1`, using `i - 1` yields `0, 1, 2, 4` for one-hot `mul_b` values `1, 2, 4, 8`.
3. If only particular bits fail, trace each generated term through the adder tree and check that it appears exactly once. A repeated array index can double one contribution and omit another. If the one-hot test passes with a multiplicand of 1, repeat it with the multiplicand's high bit set to check for truncation during the shift.
4. After the fix, verify back-to-back inputs and assert reset between clock edges with a product pending. Check that the output clears immediately and that the pending product does not appear after reset. For a 4-bit multiplier, all 256 input pairs fit in a short simulation.

Two tasks used `TopModule.sv`, a two-stage 4-bit unsigned multiplier.

- **Repeated adder input.** The generator made four shifted terms, but the second registered sum used `temp[2] + temp[2]`. With a multiplicand of 1, that expression gives 8 for multiplier value 4 and 0 for multiplier value 8. Replacing the second `temp[2]` with `temp[3]` matched the reference fix and passed all 43 grading samples.
- **Off-by-one shift.** The two registered sums already used each partial product once. Tracing the terms back to the generator located the error in `mul_a << (i - 1)`. Changing the shift to `i` matched the reference fix and passed all 43 grading samples.

In both tasks, local Icarus Verilog simulations passed all 256 input pairs on consecutive cycles and verified asynchronous reset with a product pending.
