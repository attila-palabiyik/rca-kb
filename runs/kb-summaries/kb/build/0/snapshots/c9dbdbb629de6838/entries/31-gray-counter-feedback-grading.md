# Gray counter decoder grading result

The submitted 4-bit Gray counter matched the reference on all 421 grading samples. The supplied reference changed only the final Gray-to-binary XOR, from `gray_wire[0] ^ bin_out[3]` to `gray_wire[0] ^ bin_out[1]`. The preceding assignments already accumulated Gray bits 3 through 1 into `bin_out[1]`, so that one operand change completed the prefix XOR.

The submission computed each prefix XOR directly from `gray_wire` and used nonblocking assignments to register the decoded bits. Both versions preserved the counter's register stages. The reference retained the original blocking assignments, so the local early-update symptom recorded in entry 30 does not establish that changing assignment style was required by the grader.

For similar RTL conversion bugs, expand each output bit into its input dependencies to locate a wrong operand. Separately check the first update, hold cycles, and wraparound whenever the conversion feeds a clocked counter.
