Use the same last-address condition (`DEPTH - 1` for zero-based addresses) to reset a FIFO pointer's address to zero and toggle its wrap bit on an accepted transfer.

Applies to circular FIFO pointers with separate address and wrap fields. In the synchronous FIFO `TopModule`, the read address wrapped at `DEPTH - 1`, but the wrap bit compared against the unreachable address `DEPTH`. Correcting that comparison was the reference's only functional change. The submitted fix also changed flag detection and supported depth one, and matched all 327 graded samples.
