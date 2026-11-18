# Truncated failure state in a grouped sequence detector

TopModule samples fixed, nonoverlapping six-bit groups and reports whether each equals 011100. Its failure terminal state sf6 used 4'd20, which truncates to 4'd4 and aliases the successful four-bit prefix state s4. That alias can decode a failure after four matching bits and make the next group lose alignment after a failed group.

Assigning the unused 4'd12 encoding to sf6 restores the existing transition table. Both combinational blocks now use wildcard sensitivity lists. The output decoder defaults both flags low and decodes the registered terminal states when reset is deasserted. No transition changes were needed.

A temporary Icarus Verilog testbench passed all 4,096 ordered pairs of groups and a continuous stream containing each group value. It also checked output stability under between-edge data changes and asynchronous reset from a partial group and both verdict states. No implementation attempts failed.

For a grouped Moore detector that reports a result too early or loses alignment, check the effective widths and uniqueness of state encodings before changing group-boundary transitions.
