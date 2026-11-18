# Check adder generate and propagate separately

In the 4-bit carry look-ahead adder `TopModule`, both `G` and `P` used XOR. The grading reference changed only `G` to `A_in & B_in` and kept the existing carry recurrence and sum expressions. The submitted implementation used AND for `G`, XOR for `P`, and expanded the carries into AND/OR primitives to satisfy the structural wording. It matched all 425 grading samples and passed a separate Icarus Verilog check of all 512 binary input combinations. The grading result confirms that the structural rewrite was unnecessary for matching the reference outputs.

When an adder duplicates the expressions for generate and propagate, check `1 + 1` with carry-in zero to isolate carry generation. Check `1 + 0` with carry-in zero for a false carry, then repeat with carry-in one to exercise propagation. For a small adder, compare the concatenated carry-out and sum against a widened arithmetic result for every input combination.
