# Combine active-low decoder minterms with NAND

In the `TopModule` full subtractor, `decoder_38` used `{A, B, Ci}` as its address and drove the selected output low. The difference `D` is high at addresses 1, 2, 4, and 7. The original `~(Y1_n & Y2_n | Y4_n & Y7_n)` always produced zero for binary inputs. At most one decoder line was low, so at least one of the two AND pairs stayed high and the OR stayed high.

The submitted and reference fixes both used `~(Y1_n & Y2_n & Y4_n & Y7_n)`. The borrow output `Co` already used a NAND over its correct addresses, 1, 2, 3, and 7. The submission matched all 57 graded samples. An independent Icarus Verilog test also checked both outputs for all eight binary inputs using `A - B - Ci`, with the low result bit as the difference and a negative result indicating borrow.

For an output driven from a one-hot decoder, trace the address wiring and list the addresses where the output should be high. OR the selected lines for an active-high decoder or NAND the selected lines for an active-low decoder.
