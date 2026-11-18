# Check how active-low decoder outputs are combined

**Check** the output equation against the truth-table rows where the result should be high. Read the instance's address wiring to map each row to a decoder output. With a one-of-N active-low decoder, NAND the lines for those rows. Each selected address should make the result high, and each other address should make it low.

- **The equation has the wrong lines or operators.** Correct the equation and sweep every address. An OR between two disjoint groups of ANDed active-low lines masks the single low line because the other group stays high.
- **The equation matches the truth table.** If the result still disagrees in simulation, check the decoder enable and verify that each address drives the expected line low at the instance outputs.

**Observed in `TopModule.sv`**, a full subtractor with decoder address `{A, B, Ci}`. The original difference equation ORed two AND terms before inversion, so `D` stayed low for all binary addresses. The reference and submission both replaced that OR with AND, making `D` high on addresses 1, 2, 4, and 7. The borrow equation already used the correct addresses 1, 2, 3, and 7. All 57 graded samples matched the reference.
