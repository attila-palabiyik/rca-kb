# Grading result for the 24-to-128-bit converter's second output pulse

The submitted TopModule passed all 261 grading samples. The supplied reference diff exactly matched the one-line submission. It changed the middle counter comparison in the registered valid_out expression from 12 to 10.

This is a useful check for valid-only packers with noninteger width ratios. Count accepted bits to locate word boundaries, then compare the registered valid condition with the data register's write condition. In this design, accepted inputs 6, 11, and 16 complete the three output words in each repeating group. The counter is evaluated before it increments, so both registers use counts 5, 10, and 15.
