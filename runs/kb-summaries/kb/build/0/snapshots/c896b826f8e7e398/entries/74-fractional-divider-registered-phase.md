# Fractional divider registered phase

TopModule divides by 8.7 using three 8-input-cycle output periods and seven 9-input-cycle output periods per 87-input-cycle frame. The example cycle counts conflicted with the specified divisor and parameter values. The phase flag originally fed its own inverse through combinational logic at the frame boundaries, leaving the switching state without reliable clocked storage.

Clocked the phase flag on the same input edge as the counters and used nonblocking assignments for the active-low asynchronous reset and the two toggles. This lets the last count finish under the outgoing period before the next period starts. Derived the counter widths from the larger period and the frame length, and kept the pulse comparison unchanged.

Icarus verified the expected level at each input cycle, the rising-edge count across repeated frames, and asynchronous reset during a high pulse. It passed with the default parameters and with an alternate 130-cycle frame using periods of 18 and 19. The first test launch was rejected because its cleanup used a forced removal command. Separate cleanup of the named temporary files worked.

For related divider repairs, inspect when the period selector updates relative to the period counter. Verify both phase transitions, restarting after reset, and a valid alternate schedule that exercises counter widths.
