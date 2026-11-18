# Synchronous FIFO write-pointer grading result

The submitted TopModule passed all 327 grading samples. The reference fix replaced the self-referential combinational write-pointer block with an always block triggered on the rising clock edge or falling reset edge. It used nonblocking assignments to clear the pointer on active-low reset and advance it on a write enable. This aligns the write pointer with the RAM, which samples its write address at the rising edge.

The reference retained the original read pointer, wrap logic, occupancy-based flags, and RAM enables. The submission also simplified the flags to pointer comparisons, gated RAM enables during reset, and accommodated depth one. Its separate Icarus tests exercised those changes. The grading result establishes agreement on the 327 sampled cases and gives no separate coverage information for the additional changes.

For similar RTL debugging tasks, trace the update edge of the state producer and the sampling edge of its consumer. If an otherwise symmetric read/write pair differs in how its pointers are clocked, check whether aligning the suspect pointer with the RAM is sufficient before changing flag or reset logic.
