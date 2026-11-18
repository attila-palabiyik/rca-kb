# Check the weight and use of each partial product

**Check** which multiplier bit and shift each partial product represents. Trace those terms through the intermediate sums to the output and compare them with the intended expansion of the product.

- **A term has the wrong weight.** For an unsigned binary multiplier, the term selected by multiplier bit `i` must equal the multiplicand shifted left by `i`. To isolate a term, use a nonzero multiplicand and drive the multiplier with only bit `i` set. Check the product at the pipeline's established output cycle.
- **A required term is missing or counted twice.** Correct the sum that uses the wrong term.
- **Every term appears with the intended weight.** Check whether shifts and sums retain enough bits, then verify that the terms reaching the final adder belong to the same input sample.

**Observed in `TopModule.sv`**, a two-stage unsigned 4-bit multiplier. The upper registered sum added `temp[2]` twice and omitted `temp[3]`. Changing that sum to `temp[2] + temp[3]` matched the reference on all 43 graded samples.

**Observed in another `TopModule.sv` task**, a two-stage unsigned 4-bit multiplier. Each term was selected by `mul_b[i]`, but its shift was `i-1`. This gave bit zero a shift of `-1` and gave the other terms half their intended weight. Changing the shift to `i` matched the reference on all 43 graded samples.
