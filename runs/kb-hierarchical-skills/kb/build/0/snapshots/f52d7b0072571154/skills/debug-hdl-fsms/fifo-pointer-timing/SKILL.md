---
name: fifo-pointer-timing
description: Diagnose incorrect request enables and pointer updates in synchronous RAM-backed FIFOs.
---

# FIFO enables and pointer timing

- Trace the request-to-enable path from reset before changing the flag logic. An empty FIFO has space, so the first write request should reach both RAM and the write pointer. Where each port is gated by current occupancy, writes require `!wfull` and reads require `!rempty`. Derive any boundary exceptions from the interface's simultaneous-request rules.
- Check the pointer register assignments. A pointer assigned in `always @(*)` from its own incremented value has combinational feedback. A self-assignment in the disabled branch does not make the pointer edge-triggered.
- In a synchronous RAM-backed FIFO, use an edge-triggered pointer update with nonblocking assignments. Match the specified reset and advance each pointer on the same clock edge and accepted operation as its RAM port. Use the current pointer as the RAM address and commit the increment or wrap after the edge.
- Preserve the existing wrap arithmetic, flag logic, and simultaneous-request behavior when they agree with the specification. A faulty enable can prevent correct pointer and flag logic from being exercised.
- Verify that an enable pulse between rising edges leaves FIFO state unchanged. Then check the first write and read, wrapping, and simultaneous requests at partial occupancy, full, and empty according to the interface rules.

In an earlier graded `TopModule.sv` synchronous FIFO, the reference moved the write pointer into `always @(posedge clk or negedge rst_n)` and used nonblocking assignments. In a separate graded FIFO task, both pointers were already clocked and shared their respective RAM enables. The reference's only functional change was from `winc & wfull` to `winc & (!wfull)`. The submission also gated both enables during reset, rewrote the flag comparisons, and supported depth 1. It passed all 327 samples. The reference diff establishes that the enable polarity change sufficed for the reported bug.
