# Active-low decoder outputs

When a binary decoder drives combinational outputs, list the input rows where each result should be high and map those rows to decoder addresses using the actual port wiring. With active-low decoder outputs, the selected line goes low and every other line stays high. NAND the lines for all selected rows so that any one low line asserts the result.

In the decoder-based full subtractor `TopModule`, the decoder address was `{A, B, Ci}`. The difference is high at addresses 1, 2, 4, and 7, while the borrow is high at 1, 2, 3, and 7. The original difference expression, `~(Y1_n & Y2_n | Y4_n & Y7_n)`, ORed two AND terms before inverting. At least one pair always contains two high lines, so the expression held the difference low for every binary input. Input `001` exposes the bug because subtracting the incoming borrow from zero should give both difference and borrow high.

The submitted and supplied fixes both changed the difference to `~(Y1_n & Y2_n & Y4_n & Y7_n)`. The borrow already used a NAND over the correct lines. All 57 grading samples matched, and a local Icarus Verilog test verified both outputs across all eight binary inputs by comparing `{Co, D}` with the two-bit result of `A - B - Ci`.

For another example of isolating a wrong operator in combinational arithmetic, see [Adder carry generation](adder-carry-generation.md).
