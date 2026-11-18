# Qualify output valid with word completion

When debugging a registered valid-only packer, compare the assignment to the output valid flag with the condition that writes the output data on the same edge. If a counter marks that the next accepted input will complete a word, assert output valid only when the counter is at that boundary and the input is valid. A gap at that boundary leaves the counter waiting for the completing input.

In the 24-to-128-bit `TopModule`, the original `|| valid_in` asserted `valid_out` on ordinary input beats and on idle cycles at counts 5, 10, and 15. The accepted one-line fix combined `valid_in` and the completion counts with `&&`, matching the data register's write condition. It passed all 261 grading samples, and the reference made the same logic change.

A directed test should include valid beats before completion, idle cycles immediately before a completing beat, and a continuous stream across a counter wrap. Check both the flag every cycle and the packed data on completion.
