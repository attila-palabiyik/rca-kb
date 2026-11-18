# Output valid and word completion

Applies when a word packer or similar accumulator asserts output valid before a full word is ready or reasserts it during idle cycles at a completion boundary.

1. Find the clock-edge condition that writes the output data. Trace the counter just before that edge and identify whether it counts accepted inputs or elapsed clocks. With nonblocking assignments, a counter that has already counted five inputs still reads as five on the edge that accepts the sixth.
2. Compare the data-write condition with the valid condition. Test both cases where they can diverge. Drive an accepted input before the completion count, then pause with the counter at the completion count before sending the final input. If valid uses OR between acceptance and the completion count, both cases produce a false valid pulse. When the interface marks each newly written word with a pulse, use the same acceptance-and-completion condition for that pulse and the data write.
3. Check packing independently before changing counter thresholds or slices. For `TopModule.sv`, the 24-to-128-bit packer completed words on accepted inputs 6, 11, and 16 of each 16-input group. Those words used 8, 16, and 24 high bits of the incoming beat, respectively. A bit-stream scoreboard checked bit order and carryover across those boundaries, with gaps immediately before completion and an asynchronous reset while output valid was high.

Source task was the `TopModule.sv` width converter with premature and idle-cycle output valid. The counter thresholds and packing slices already produced the expected words. Changing OR to AND in the registered `valid_out` condition passed all 261 grading samples.
