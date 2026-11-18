---
name: fifo-pointer-timing
description: Diagnose incorrect request enables, pointer updates, and wraparound in synchronous RAM-backed FIFOs.
---

# FIFO enables and pointer timing

- Trace the request-to-enable path from reset before changing the flag logic. An empty FIFO has space, so the first write request should reach both RAM and the write pointer. Where each port is gated by current occupancy, writes require `!wfull` and reads require `!rempty`. Derive any boundary exceptions from the interface's simultaneous-request rules.
- Check the pointer register assignments. A pointer assigned in `always @(*)` from its own incremented value has combinational feedback. A self-assignment in the disabled branch does not make the pointer edge-triggered.
- In a synchronous RAM-backed FIFO, use an edge-triggered pointer update with nonblocking assignments. Match the specified reset and advance each pointer on the same clock edge and accepted operation as its RAM port. Use the current pointer as the RAM address and commit the increment or wrap after the edge.
- For pointers split into a RAM address and a wrap bit, compare their next-state conditions. With addresses `0` through `DEPTH - 1`, an accepted operation at `DEPTH - 1` must reset the address to zero and toggle the wrap bit on the same edge. Check both pointers. A wrap-bit comparison against `DEPTH` never fires because the address has already wrapped before reaching that value.
- Preserve the existing wrap arithmetic, flag logic, and simultaneous-request behavior when they agree with the specification. A faulty enable can prevent correct pointer and flag logic from being exercised.
- Verify that an enable pulse between rising edges leaves FIFO state unchanged. Then check the first write and read and simultaneous requests at partial occupancy, full, and empty according to the interface rules. Fill and drain the FIFO through both pointer wraps. Check that the final read returns the last queued word, asserts empty, and clears full. Refill to verify that full can assert again.

In an earlier graded `TopModule.sv` synchronous FIFO, the reference moved the write pointer into `always @(posedge clk or negedge rst_n)` and used nonblocking assignments. In a separate graded FIFO task, both pointers were already clocked and shared their respective RAM enables. The reference's only functional change was from `winc & wfull` to `winc & (!wfull)`. The submission also gated both enables during reset, rewrote the flag comparisons, and supported depth 1. It passed all 327 samples. The reference diff establishes that the enable polarity change sufficed for the reported bug.

In the graded `TopModule.sv` read-pointer wraparound task, the reference's only functional change was to compare the read address against `DEPTH - 1` when toggling the wrap bit. The submission made that change and also set a minimum address width of one bit for depth 1. It matched all 327 reference samples. Separate Icarus checks passed at depths 1, 3, and 16.
