# Write-enable polarity in a synchronous FIFO

Applies when reset produces the expected empty and full flags, but the FIFO stays empty after a write request on a rising edge, or the RAM write enable is high only when the FIFO is full.

1. Start from reset and confirm `rempty = 1` and `wfull = 0`. Assert `winc` for one rising edge with `rinc = 0`. Check the RAM write enable before that edge, then check the write pointer and empty flag after it. If the enable is low while the request is high and there is room, trace the enable expression first.
2. Check the polarity of both boundary flags at the point where requests are accepted. In this FIFO, `wenc = winc & wfull` blocked the first write and would allow a write if full were asserted. The fix was `wenc = winc & !wfull`. The read side already used `rinc & !rempty`. Each accepted enable drove both its RAM port and its pointer update. The pointer block already sampled the same rising edge as the RAM, and the reset flags were consistent with the pointer values.
3. Verify the first write and readback, then fill, attempt an extra write, and drain in order across wraparound. Exercise simultaneous requests in the interior and at both boundaries. With this design's current-state flags, both transfers are accepted in the interior, only the read is accepted at full, and only the write is accepted at empty.

Source task was `TopModule.sv`, a parameterized synchronous FIFO with shared write acceptance for the pointer and dual-port RAM. The submitted fix also gated transfers during reset and added address sizing for `DEPTH=1`. It matched all 327 grading samples. The supplied reference changed only the write-enable polarity in the logic, so neither addition was required to correct the graded bug.
