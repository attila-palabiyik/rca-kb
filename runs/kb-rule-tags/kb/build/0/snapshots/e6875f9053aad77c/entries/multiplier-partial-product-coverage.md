Check that each multiplier bit contributes its shifted partial product exactly once across the registered sums of an unsigned shift-and-add multiplier.

Applies when a multiplier generates a partial product for each input bit and combines them in groups. In the 4-bit pipelined `TopModule` multiplier, the upper sum added `temp[2]` twice and omitted `temp[3]`. Changing the sum to `temp[2] + temp[3]` matched the reference fix and passed all 43 grading samples.
