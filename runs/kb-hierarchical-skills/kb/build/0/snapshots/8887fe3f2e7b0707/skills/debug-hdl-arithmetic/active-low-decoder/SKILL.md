---
name: active-low-decoder
description: Debug arithmetic outputs formed from active-low decoder lines in Verilog and SystemVerilog.
---

# Active-low decoder logic

- Read the decoder instance to determine the address bit order. For each output, list the addresses where the arithmetic truth table requires a `1`.
- For an active-low decoder, NAND all the lines for those addresses. Any selected line going low should assert the output. An OR between separate AND groups inside the negation can mask that low because the other group stays high.
- For a three-input circuit, simulate all eight input combinations against the arithmetic directly. For a full subtractor, compute `A - B - Ci` with a signed integer and compare its low bit to `D` and its sign to `Co`.

In the graded `TopModule` full subtractor, `{A, B, Ci}` addressed the 3-to-8 decoder. Replacing the OR between the two AND groups in `D` with an AND produced `~(Y1_n & Y2_n & Y4_n & Y7_n)`. The existing borrow expression used lines 1, 2, 3, and 7. Icarus Verilog passed all eight input combinations, and all 57 grading samples matched the reference.
