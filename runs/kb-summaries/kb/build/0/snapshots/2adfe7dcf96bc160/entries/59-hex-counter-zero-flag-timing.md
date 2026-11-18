# Settable hexadecimal counter zero flag timing

TopModule updated its four-bit count on the rising edge, but the separately registered zero flag sampled the previous count. Reset also cleared the flag while setting the count to zero.

The fix computes the next four-bit count from the set input or increment, then registers that count and its zero comparison on the same edge. Active-low asynchronous reset sets the count to zero and asserts the flag. Four-bit overflow implements wraparound.

An independent Icarus Verilog test passed two full count cycles, every ordered pair of old count and set value, increment after set, stability between rising edges, and asynchronous reset with set active. The first RTL implementation passed.

For counters with registered status outputs, check whether the specification ties each flag to the count before or after the clock edge. Check reset, wraparound, and explicit loads of zero separately.
