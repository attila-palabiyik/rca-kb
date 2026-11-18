# Combine active-low decoder outputs with NAND

In the full subtractor `TopModule`, the 3-to-8 decoder used `{A, B, Ci}` as its address. Difference is high for addresses 1, 2, 4, and 7. The original `~(Y1_n & Y2_n | Y4_n & Y7_n)` kept difference low for every binary input because at least one of the two AND terms was always high. Replacing it with `~(Y1_n & Y2_n & Y4_n & Y7_n)` made any selected low output assert the difference. Borrow already used the correct NAND over addresses 1, 2, 3, and 7.

The one-line change matched the reference fix and all 57 grading samples. An independent Icarus Verilog test covered all eight binary inputs, checking difference against the low bit of `A - B - Ci` and borrow against whether that result was negative.

For similar combinational bugs, write down the decoder address order and the addresses where each result should be high. With active-low decoder outputs, NAND the lines for those addresses. For a small input space, verify every combination against an arithmetic or truth-table model.
