---
name: gray-to-binary
description: Diagnose incorrect XOR dependencies and shift distances in Verilog and SystemVerilog Gray-code converters and counters.
---

# Check Gray-code conversion

- Trace the XOR chain from the most significant bit down. The top bits are equal. Each lower `bin[i]` is `gray[i] ^ bin[i+1]`, equivalent to `^gray[MSB:i]`. Check each index for a copied reference that skips the adjacent decoded bit.
- Use a directed value with different decoded bits at the suspected indices. For example, 4-bit Gray `0010` decodes to binary `0011`. Its decoded bit 1 is high while bit 3 is low, so using bit 3 in the bit 0 equation produces `0010`.
- Check the encoder separately. Binary-to-Gray conversion is `binary ^ (binary >> 1)` because each lower Gray bit combines adjacent binary bits. Binary `0010` should encode to `0011`. A two-bit shift produces `0010` and makes the transition from the encoding of binary `0001` change two bits.
- If the conversion error accounts for the failure, try correcting the expression with the existing register boundaries and reset behavior. Check the sequence from reset through wraparound, including the clock edges on which the output holds or advances.

In the graded 4-bit `TopModule` Gray counter, the reference fix changed only `bin_out[0]` from `gray_wire[0] ^ bin_out[3]` to `gray_wire[0] ^ bin_out[1]`. The submitted implementation corrected the same dependency and used combinational conversion with an explicit every-other-cycle enable. It matched all 421 grading samples.

In a separate graded 4-bit `TopModule` Gray counter, the decoder already used the adjacent binary bit at every step. The reference fix changed only the encoder shift from `>> 2` to `>> 1`, preserving the original register stages. The submitted implementation used the corrected shift, combinational conversion, and an explicit every-other-cycle enable. It matched all 421 grading samples. Icarus Verilog also verified the full sequence, wraparound, and reset asserted between clock edges for the submitted implementation.
