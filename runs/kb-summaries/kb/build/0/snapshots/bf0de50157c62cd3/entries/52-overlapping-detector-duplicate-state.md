# Duplicate state encoding in an overlapping sequence detector

TopModule detects 1011 and registers a one-cycle flag on the rising edge after the last bit. S2 and S3 both encoded 2, so receiving the third bit of 1011 left the machine in the S2 case and prevented it from reaching S4, the match state.

Assigning S3 the value 3 restored the distinct prefix state. The existing transitions already retained the matched prefix needed for overlap. Icarus Verilog passed the 10110111 example with two pulses, asynchronous reset while the flag was high, and a delayed sliding-window comparison for all 4096 twelve-bit streams with a trailing clock.

For sequence FSMs with an unreachable match state, check for duplicate state encodings before changing transitions or flag timing.
