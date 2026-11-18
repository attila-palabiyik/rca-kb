# Active-low decoder full subtractor

TopModule computes the difference and borrow for A minus B minus Ci, using a 3-to-8 decoder addressed by {A, B, Ci}. The original difference equation ORed two pairs of ANDed decoder outputs before inversion. At most one decoder output is low, so at least one pair stays high and this expression forces D low on all eight binary inputs.

The difference is high for decoder addresses 1, 2, 4, and 7. Replacing the OR in the expression with AND makes the four active-low outputs feed a NAND. The existing borrow equation already NANDs addresses 1, 2, 3, and 7, where B plus Ci exceeds A. An Icarus Verilog testbench checked both outputs for every input combination against the low bit and sign of the integer subtraction. All eight passed.

This applies to combinational designs that use active-low decoder outputs to implement truth-table minterms.
