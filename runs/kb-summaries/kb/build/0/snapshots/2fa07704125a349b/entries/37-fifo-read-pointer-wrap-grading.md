# Grading follow-up for synchronous FIFO read pointer wrap

The submitted TopModule matched all 327 reference samples. The reference's sole functional change was to toggle the read pointer's wrap bit at `DEPTH-1` instead of `DEPTH`. This makes the wrap-bit toggle occur on the same accepted read that sends the address back to zero. The reference retained the original occupancy-based full and empty logic.

The submission also used direct pointer comparisons for the flags, gated the RAM enables during reset, and supported depth one with a one-bit RAM address. The reported grading result establishes agreement across the 327 samples. Separate Icarus tests exercised depth one, other depths, reset, and simultaneous requests, as recorded in entry 36.

For similar FIFO bugs, trace the address rollover and the wrap-bit update together. A full-depth fill followed by a complete drain checks whether an accepted read at the last address makes both updates and restores the empty flag.
