# Synchronous FIFO read pointer wrap

TopModule stored data in a dual-port RAM. The read address returned to zero at DEPTH - 1, but its wrap bit toggled only at DEPTH. The read pointer therefore kept the same wrap bit through every cycle of addresses. Filling and draining an entire FIFO could leave the full flag asserted even after all items were read.

Both pointers now return to address zero and toggle their wrap bits at DEPTH - 1 on an accepted operation. With equal RAM addresses, matching wrap bits indicate empty and differing wrap bits indicate full. The original acceptance policy blocks writes when full and reads when empty, while simultaneous requests within those limits both proceed. RAM enables are gated during reset. The address width has a minimum of one bit in both the FIFO and RAM to support DEPTH = 1.

The first implementation passed an Icarus Verilog scoreboard at depths 1, 2, 3, 5, 16, and 17 with varied data widths. It covered repeated fills and drains, overflow and underflow attempts, simultaneous requests, reset during traffic, flags before and after the clock edge, and held read output between accepted reads. No implementation retries were needed.

For FIFO pointer failures, check the wrap-bit toggle against the exact condition that resets the RAM address to zero. Repeated full-to-empty transitions expose a stale wrap bit even if early reads return the expected data.
