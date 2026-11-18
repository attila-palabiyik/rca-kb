---
name: fifo-pointer-timing
description: Diagnose synchronous FIFO pointers that change between clock edges or disagree with the RAM's accepted operations.
---

# FIFO pointer timing

- Trace the pointer register assignments and their enables before changing the full or empty logic. A pointer assigned in `always @(*)` from its own incremented value has combinational feedback. A self-assignment in the disabled branch does not make the pointer edge-triggered.
- In a synchronous RAM-backed FIFO, use an edge-triggered pointer update with nonblocking assignments. Match the specified reset and advance each pointer on the same clock edge and accepted operation as its RAM port. Use the current pointer as the RAM address and commit the increment or wrap after the edge.
- Preserve the existing wrap arithmetic, flag logic, and full and empty request rules when they agree with the specification and the fault is confined to pointer timing. Avoid changing acceptance of simultaneous requests at the boundaries without a requirement for that behavior.
- Verify that an enable pulse between rising edges leaves FIFO state unchanged. Then check the first write and read, wrapping, and simultaneous requests at partial occupancy, full, and empty according to the interface rules.

In the graded `TopModule.sv` synchronous FIFO, the reference fix only moved the write pointer into `always @(posedge clk or negedge rst_n)` and used nonblocking assignments, matching the existing read pointer. It retained the wrap and occupancy arithmetic and the RAM enables. The submitted implementation also revised the flag comparison and passed all 327 reference samples. The reference diff shows that the flag rewrite was unnecessary for the reported bug.
