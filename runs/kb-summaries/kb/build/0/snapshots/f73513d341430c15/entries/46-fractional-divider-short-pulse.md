# Fractional divider short pulse

TopModule implements an 8.7 divider as three 8-cycle periods followed by seven 9-cycle periods. The numerical example in the task conflicted with the requested ratio. The supplied parameters give exactly 10 output periods per 87 input periods.

The original short-period expression shifted the period right by three before applying an inclusive bound, producing only three high input cycles per 8-cycle period. The default 9-cycle period already had four high input cycles. Both branches now compare the period counter against the period shifted right by one with an exclusive bound, yielding four high cycles in each default period. Counter widths are derived from the period and frame parameters to accommodate larger overrides.

A temporary Icarus Verilog test checked every output level, rising edge counts across repeated frames, and asynchronous reset during a high pulse for both the default schedule and a 130-cycle schedule with periods of 18 and 19. The first test command's cleanup was rejected before execution, so the successful run removed each temporary file explicitly.

For related dividers, count complete output periods per schedule and check the high and low intervals independently. Use a second valid schedule that exercises the counter widths when checking parameterization.
