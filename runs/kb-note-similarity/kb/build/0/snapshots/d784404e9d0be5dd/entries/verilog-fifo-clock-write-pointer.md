# Clock a synchronous FIFO pointer on accepted transfers

In the SystemVerilog `TopModule` synchronous FIFO, the write pointer updated in an `always @(*)` block from its own incremented value. The write enable also depended on the full flag derived from that pointer. While a write was enabled, this created combinational feedback where the pointer should have held the address for the RAM to sample at the rising edge.

The reference fix changed only the write pointer block. It matched the read pointer's `posedge clk or negedge rst_n` sensitivity, used nonblocking assignments, and held the pointer implicitly when the write enable was low. The submitted fix also simplified the flags to address and wrap-bit comparisons and gated RAM enables during reset. It matched all 327 graded samples. Icarus tests also passed at depths 1, 2, 3, 16, and 17. The reference shows that the pointer update alone was sufficient.

When one pointer already uses the right clock and reset, use it as a template for the other. Preserve the existing acceptance rules unless the specification calls for changing them. This FIFO accepts both transfers when both are enabled. At full it accepts only the read, and at empty it accepts only the write. Test those boundary cases as well as simultaneous transfers between them.
