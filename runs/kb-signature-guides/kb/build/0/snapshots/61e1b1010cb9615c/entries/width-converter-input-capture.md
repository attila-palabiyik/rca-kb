# Input capture in a width converter

Applies when a word packer reports completion on the expected clock but a field sourced from an earlier input contains stale data or changes with data presented during idle cycles.

1. Check output timing and data separately. In the 8-to-16-bit `TopModule.sv` converter, the phase flag toggled only on accepted inputs, and both the output write and registered `valid_out` used the same condition: `flag && valid_in`. This already marked every second accepted byte, so changing the completion condition would not repair the data.
2. Trace the stored field and the live input separately on the completion edge. For `{data_r, data_in}`, the high byte comes from the pre-edge value of `data_r`, while the low byte comes from the current input. Check both branches of the register's enable. The original `valid_in ? data_r : data_in` held the register on valid cycles and loaded it on idle cycles.
3. Simulate distinct bytes both back to back and with a gap in which invalid input data changes. For example, send valid `12`, invalid `AB` and `CD`, then valid `34`. Check that the output is `1234` and that valid pulses only when the second byte is accepted. Reset between bytes to check that an incomplete pair is discarded.

In the graded `TopModule.sv` task, capturing `data_r` only on the first valid byte of each pair passed all 141 samples. The provided reference captures `data_r` on every valid byte with `valid_in ? data_in : data_r`. On the second-byte edge, nonblocking assignments assemble the output using the previously captured first byte, so the simultaneous register update is compatible with the reference output.
