---
name: gray-to-binary
description: Diagnose incorrect bit dependencies in Verilog and SystemVerilog Gray-to-binary converters and Gray-code counter feedback.
---

# Check Gray-to-binary conversion

- Trace the XOR chain from the most significant bit down. The top bits are equal. Each lower `bin[i]` is `gray[i] ^ bin[i+1]`, equivalent to `^gray[MSB:i]`. Check each index for a copied reference that skips the adjacent decoded bit.
- Use a directed value with different decoded bits at the suspected indices. For example, 4-bit Gray `0010` decodes to binary `0011`. Its decoded bit 1 is high while bit 3 is low, so using bit 3 in the bit 0 equation produces `0010`.
- If the conversion error accounts for the failure, try correcting the expression with the existing register boundaries and reset behavior. Check the sequence from reset through wraparound, including the clock edges on which the output holds or advances.

In the graded 4-bit `TopModule` Gray counter, the reference fix changed only `bin_out[0]` from `gray_wire[0] ^ bin_out[3]` to `gray_wire[0] ^ bin_out[1]`. The submitted implementation corrected the same dependency and used combinational conversion with an explicit every-other-cycle enable. It matched all 421 grading samples.
