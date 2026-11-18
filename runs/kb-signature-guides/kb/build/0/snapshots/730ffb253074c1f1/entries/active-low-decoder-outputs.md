# Combining active-low decoder outputs

Use this guide when a combinational output should assert for several decoder addresses and each address drives its selected decoder line low.

1. Read the address bit order and enable at the decoder instance. Build the output truth table from the specification, then map each row that should assert to its decoder line. In the `TopModule` full subtractor, the decoder was enabled and the address was `{A, B, Ci}`. Difference `D` should assert at addresses 1, 2, 4, and 7. Borrow `Co` should assert at 1, 2, 3, and 7.
2. Compare the line numbers and the operators separately. To assert when any listed active-low line goes low, NAND those lines together. The original difference expression used the correct line numbers but ORed two disjoint AND groups inside the inversion. With just one decoded line low, at least one group stays high, so the difference stays low on every binary input. The enable, address order, and borrow expression all agreed with the truth table.
3. Sweep the binary input combinations against an independent model. The Icarus Verilog test used integer `A - B - Ci`, checking bit 0 for `D` and a negative result for `Co`.

The submitted fix changed the middle `|` to `&` in the difference expression. The reference made the same one-line change, and all 57 grading samples matched.
