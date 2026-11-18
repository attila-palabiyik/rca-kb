When a FIFO uses active-high full and empty flags to block transfers, check that its write enable requires a deasserted full flag and its read enable requires a deasserted empty flag.

Applies when each transfer enable drives both the RAM port and its corresponding pointer. In the `TopModule` synchronous FIFO with a reversed write-enable condition, the reference's only functional change was `winc & (!wfull)`. The submission also gated transfers during reset, compared pointers directly for the flags, and supported depth one. It matched all 327 graded samples.
