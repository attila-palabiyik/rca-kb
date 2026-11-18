# Input capture in a width converter

Applies when a word packer reports completion on the expected clock but a field sourced from an earlier input is stale, reflects idle-cycle data, or repeats the current input.

1. Check output timing and data separately. In both 8-to-16-bit `TopModule.sv` tasks, the phase flag toggled on accepted inputs. The output write and registered `valid_out` both used `flag && valid_in`, which already marked every second accepted byte. The fault was in the high-byte capture.
2. Trace the stored field and the live input separately on the completion edge. For `{data_r, data_in}`, the high byte must come from the first accepted input and the low byte from the current input. Check the storage event control as well as the enable.
   - With a clocked register, an inverted enable such as `valid_in ? data_r : data_in` holds during valid cycles and loads idle data.
   - With `always @(*)`, the self-holding assignment `data_r = valid_in ? data_in : data_r` describes a transparent latch. Even with the correct enable polarity, the latch follows the second byte as soon as it is present with `valid_in` high. The output register can then capture that byte in both halves.
3. Simulate distinct bytes both back to back and with a gap in which invalid input data changes. For example, send valid `12`, invalid `AB` and `CD`, then valid `34`. Check that the output is `1234` and that valid pulses only when the second byte is accepted. Reset between bytes to check that an incomplete pair is discarded.

In the latch task, replacing the latch with a rising-edge register with active-low asynchronous reset and loading only on the first accepted byte passed all 141 grading samples. The supplied fix loads the register on every accepted byte. Because both the capture and the output write use nonblocking assignments, the output sees the saved first byte on the edge that accepts the second byte, before the capture register updates. First-byte-only capture also passed all 141 samples in the earlier inverted-enable task.
