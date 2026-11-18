# Check when a memory address pointer advances

**Check** what drives each current address pointer used by a clocked memory port. The memory must sample the current address on the edge that accepts the operation. The pointer should advance on that same edge, using the same acceptance condition.

- **A combinational block feeds the next address back into the current pointer.** Put the pointer update in a clocked block with a nonblocking assignment. Use the memory port's clock and enable, and follow the design's reset behavior. Verify that one accepted operation advances the pointer once and that a blocked operation leaves it in place.
- **The pointer already advances on the correct edge under the same enable.** Check the wrap calculation and the full and empty conditions if operations still fail at the buffer boundaries.

**Observed in `TopModule.sv`**, a synchronous FIFO with dual-port RAM. The write pointer fed its next address back through an `always @(*)` block, while the RAM write port and the read pointer used the rising clock edge. The reference fix clocked the write pointer and used nonblocking assignments, preserving its active-low asynchronous reset and the existing full and empty logic. The submitted fix also changed the flag calculation and added depth-one handling. It matched all 327 graded samples. The reference diff shows that those additional changes were unnecessary for the reported bug.
