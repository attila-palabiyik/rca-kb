# Clocking a synchronous FIFO write pointer

TopModule used a self-referential combinational block to update the write pointer. Holding write enable could move the pointer before a rising edge while the dual-port RAM only wrote on that edge. The read pointer already used a clocked update.

The fix registers both pointers on the RAM clock and resets them asynchronously. Each pointer toggles its extra bit when its address wraps at DEPTH - 1. Equal addresses indicate empty when the wrap bits agree and full when they differ. The fix preserves the existing full/empty gating of requests, so a simultaneous request at a boundary services only the operation currently permitted. RAM enables are gated during reset. The supplied RAM's address port is two bits at depth one because its declared range becomes [-1:0]. Using a matching width for that case allows address zero and the wrap bit to behave as intended.

A temporary Icarus Verilog scoreboard used the supplied RAM and passed directed and randomized tests with depths 1, 2, 3, 5, 16, and 17 and varied data widths. It checked data order, output hold timing, flags between edges, simultaneous requests at boundaries, wraparound, and reset. There were no failed implementation attempts.

For synchronous FIFO debugging, compare when pointers advance with when RAM samples its address. Test simultaneous requests both inside the capacity limits and at each boundary using the design's existing acceptance policy.
