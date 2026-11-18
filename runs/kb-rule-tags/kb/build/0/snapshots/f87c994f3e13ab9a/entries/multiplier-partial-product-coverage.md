For an unsigned shift-and-add multiplier, check that each zero-indexed multiplier bit `i` selects the multiplicand shifted left by `i` and that its partial product contributes exactly once to the final sum.

Applies when a multiplier generates a partial product for each input bit and combines them in groups. In the 4-bit pipelined `TopModule` multiplier, the upper sum added `temp[2]` twice and omitted `temp[3]`. Changing the sum to `temp[2] + temp[3]` matched the reference fix and passed all 43 grading samples.

In another 4-bit pipelined `TopModule` task, the partial-product generator used `mul_a << (i-1)`. Changing the shift to `i` matched the reference fix and passed all 43 grading samples.
