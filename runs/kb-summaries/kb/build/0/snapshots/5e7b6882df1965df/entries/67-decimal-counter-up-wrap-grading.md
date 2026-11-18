# Decimal up/down counter wrap grading

All 289 graded samples matched after TopModule changed the up-count comparison from 10 to `4'd9` and sized the wrap assignment as `4'd0`. The supplied correct diff changed only the comparison from 10 to 9 and kept the original unsized zero assignment. The submitted sized literals produced the same behavior on all graded samples.

The result confirms that the wrap threshold was the functional bug. The original registered zero flag already provided the specified one-cycle delay. This applies to bounded counters with a separate status flag. Check the transition from the highest legal count and compare the flag against the pre-edge count when its specification calls for a one-cycle delay.
