# Check which partial products feed each sum

**Check** which multiplier bit and shift each partial product represents. Trace those terms through the intermediate sums to the output and compare them with the intended expansion of the product.

- **A required term is missing or counted twice.** Correct the sum that uses the wrong term. To isolate the fault, use a nonzero multiplicand and drive the multiplier with one bit set at a time. Check the result at the pipeline's established output cycle.
- **Every term appears with the intended weight.** Check whether shifts and sums retain enough bits, then verify that the terms reaching the final adder belong to the same input sample.

**Observed in `TopModule.sv`**, a two-stage unsigned 4-bit multiplier. The upper registered sum added `temp[2]` twice and omitted `temp[3]`. Changing that sum to `temp[2] + temp[3]` matched the reference on all 43 graded samples.
