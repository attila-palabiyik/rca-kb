# Check the FIFO request gates and pointer timing

In a synchronous FIFO `TopModule` task with a write-enable bug, `winc & wfull` blocked the first write after reset because `wfull` was low. The reference changed the gate to `winc & (!wfull)`, leaving `rinc & (!rempty)` as the read gate. The write enable drives both the RAM write port and the write pointer advance. Before changing flag arithmetic or wraparound, check whether the first request from empty reaches both consumers and whether a request while full leaves the write pointer and stored data alone.

The submitted repair also gated both enables with reset, switched the flags to direct pointer comparisons, and added support for depth one. It passed all 327 grading samples. The reference needed only the write-enable polarity change for behavior. The grading result establishes agreement on those samples, and depth-one coverage came from a separate Icarus test of the submission.

In a separate synchronous FIFO `TopModule` task with a pointer timing bug, the write pointer updated in `always @(*)` from its own current value whenever a write was enabled. The self-assignment in the hold branch could not enforce one advance per clock. The RAM writes on the rising edge, so the pointer must still present the current slot at that edge.

The reference patch changes only the write pointer block. It uses `always @(posedge clk or negedge rst_n)` and nonblocking assignments for reset and enabled updates, matching the existing read pointer. The submitted rewrite made that same timing change and also revised the flag logic and parameter handling. It matched all 327 grading samples. The smaller reference patch shows that the original flag logic and RAM interface could be preserved for this bug.

For similar failures, check that an accepted request makes the RAM use the pre-edge address and advances the corresponding pointer exactly once after the edge. Drive requests between edges and check the flags before and after the edge. Fill and drain across wraparound, and exercise simultaneous requests at partial occupancy and at both boundaries.
