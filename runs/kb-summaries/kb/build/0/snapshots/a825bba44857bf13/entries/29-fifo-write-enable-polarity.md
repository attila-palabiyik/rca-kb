# Synchronous FIFO write-enable polarity

In this TopModule, the synchronous FIFO used a dual-port RAM and clocked read and write pointers. The original `wenc = winc & wfull` blocked the first write after reset because the FIFO started empty. The same enable drove the RAM write and write-pointer advance, so neither could make progress from empty.

The submitted file passed all 327 grading samples. The reference's sole functional change was `wenc = winc & (!wfull)`. Its pointer updates, occupancy-based flags, read enable, and RAM behavior stayed as supplied.

The submission also gated both RAM enables during reset, used direct pointer comparisons for the flags, and supported one-entry RAM addressing. Its separate Icarus tests passed directed and randomized cases at widths 1, 8, and 17 and depths 1, 2, 3, 5, 16, and 17. The grading report establishes agreement on its 327 samples and gives no separate coverage information for those additional changes.

For similar FIFO repairs, trace the shared enable through both the RAM and its pointer. Start with a write to a freshly reset FIFO and then try another write after filling it. These two cases expose a full-flag polarity error while leaving pointer and flag logic in isolation from other changes.
