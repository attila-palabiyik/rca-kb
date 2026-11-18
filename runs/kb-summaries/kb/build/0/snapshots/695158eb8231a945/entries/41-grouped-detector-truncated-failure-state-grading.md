# Grading result for the grouped detector's truncated failure state

The submitted TopModule matched the reference on all 1,215 grading samples. The reference changed one line, replacing sf6 = 4'd20 with sf6 = 4'd12. The original literal truncated to 4'd4 and collided with s4, so the terminal failure state shared an encoding with the state reached after four matching bits.

The submitted solution also converted both combinational blocks to wildcard sensitivity lists and simplified the reset-gated output decoder. Those changes passed the same grading samples, while the reference establishes that the encoding change alone fixes the bug. The original transition paths already consumed six bits per group and evaluated the first bit of the next group directly from either terminal state.

For an FSM with early verdicts or lost group alignment, check whether every state literal fits its declared width and has a unique effective value. A duplicate terminal encoding can affect both output decoding and which transition branch is selected.
