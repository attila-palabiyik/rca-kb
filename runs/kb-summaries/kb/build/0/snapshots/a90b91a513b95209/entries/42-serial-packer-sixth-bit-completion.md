# Complete a six-bit word on the sixth valid input

TopModule converts valid serial bits to a six-bit word with the earliest bit at bit 0. The counter wrapped at four, so the output condition at five was unreachable. Changing only the wrap point would also leave the valid flag able to assert during an input gap after five bits. The registered ready output dropped during reset and missed input on the first clock after release, while this task explicitly required ready to be always high.

The fix ties ready high, keeps the first five accepted bits in a shift register, and captures the output with a one-cycle valid pulse when the sixth bit arrives. Reset clears partial input and the output registers. The first implementation passed an independent Icarus test covering all 64 words, uninterrupted input, gaps before the sixth bit, reset during a partial group, and valid input on the first clock after release.

For similar serial packers, treat the counter as the number of bits already accepted and check that the output write and the valid assertion use the same completion event.
