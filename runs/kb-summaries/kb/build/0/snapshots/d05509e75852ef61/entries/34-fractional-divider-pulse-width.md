# Fractional divider pulse width

TopModule uses an active-low asynchronous reset and combines three 8-cycle periods with seven 9-cycle periods. The stated output-cycle arithmetic was inconsistent with the supplied parameters. The counter schedule gives 10 output periods per 87 input periods, which matches the requested 8.7 divisor.

The original short-period comparison held the output high for six input cycles. A cycle-by-cycle Icarus simulation failed at offset four of the first period. Changed both registered comparisons to use an exclusive upper bound of half the active period, rounded down. The resulting default pulse widths are 4 high and 4 low for divide-by-8 and 4 high and 5 low for divide-by-9. Derived the counter widths from the parameters to cover larger valid schedules.

The same simulation passed after the fix for the default schedule and a 130-cycle schedule using periods of 18 and 19. It checked individual output levels, the number of rising edges over repeated frames, and asynchronous reset during a high pulse.

For similar fractional divider repairs, trace the pre-edge period counter and test the two switching boundaries and reset separately. Derive the average divisor from the combined period lengths and the number of complete output periods in each frame.
