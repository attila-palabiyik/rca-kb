---
name: debug-verilog-decoder-logic
description: Diagnose incorrect combinational outputs assembled from decoder lines in Verilog or SystemVerilog, especially active-low decoders.
---

# Debug Verilog decoder output logic

1. Read the instance wiring and the decoder's address expression to map each output line to its input combination. Check the enable and output polarity before deriving the output logic.
2. Derive the rows that assert each destination output from its specification. For an active-high output driven by active-low decoder lines, NAND the lines from those rows. An OR of AND groups inside the final inversion can mask a selected low because an untouched group still evaluates to one. Check each destination independently before changing its equation.
3. For a small decoder, exhaustively drive the binary inputs and compare every destination to an independent reference. For a full subtractor, compute `A - B - Ci` in a signed integer, using its low bit for the difference and its sign for the borrow.

## Observed result

In the 3-to-8 decoder full-subtractor task in `TopModule.sv`, the address was `{A, B, Ci}`. Difference was asserted on rows 1, 2, 4, and 7, while borrow was asserted on rows 1, 2, 3, and 7. The submitted patch replaced the OR between the two groups in the difference expression with AND, matching the supplied correct fix. Both outputs passed all eight binary combinations in Icarus Verilog, and all 57 graded samples matched the reference.
