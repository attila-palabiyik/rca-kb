# Decoding terminal states in a grouped sequence detector

TopModule checked consecutive, nonoverlapping six-bit groups for 011100. Its transition table already counted every bit of a group after the first mismatch. On the sixth rising edge the state register entered s6 or sf6, but the clocked output block read the previous state and reported the result on the seventh edge.

The fix kept the state encodings and transitions and used a wildcard combinational block to decode the two registered terminal states. This produces mutually exclusive result pulses immediately after the sixth rising edge and clears them on the first edge of the next group. The asynchronous reset puts the state register in idle, which clears both outputs.

Icarus Verilog verified all 4,096 adjacent group pairs, output stability when data changes between clocks, and asynchronous reset from a partial group and from both terminal states. The first test launch was rejected for its recursive cleanup command. A Python temporary directory inside the workspace let the simulation run and cleaned up its files. The task was verified locally.

This applies to Moore FSMs whose registered state already marks the cycle when an output is due. Trace entry to and exit from the terminal states before deciding whether an extra output register is appropriate.
