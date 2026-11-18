# Check the polarity of a FIFO port enable

**Check** the enable sampled by each port when its request is high. Apply the interface's acceptance rules to the pre-edge flags. For a FIFO that blocks writes while full and reads while empty, a write request should be accepted after reset when the FIFO is empty and blocked when it is full. A read request should be blocked when the FIFO is empty and accepted when it is full.

- **A request is accepted in the forbidden state and blocked in the allowed state.** Correct the flag polarity in the port enable. Verify the first write after reset and the behavior of requests at both boundaries.
- **The enable agrees with the acceptance rules.** If operations fail near a boundary, trace the pointer indices and wrap bits through the last RAM address and compare the resulting flags with the expected occupancy.

**Observed in `TopModule.sv`**, a synchronous FIFO with dual-port RAM and an inverted write enable. Both the RAM and the write pointer used `winc & wfull`, so a write request could not fill the empty FIFO after reset. The reference changed the enable to `winc & (!wfull)`. The submitted version also gated both enables during reset, used direct pointer comparisons for the flags, and supported depth one. It matched all 327 graded samples. The reference retained the original flag and address logic.
