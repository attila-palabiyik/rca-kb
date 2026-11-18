# Aligning a traffic light and countdown on each transition

TopModule drove its light outputs through delayed copies of the state and reloaded the countdown from output edges. The reset left all lights off, the red state asserted two buffered lights, and both the early transition comparison and delayed reload let the visible timer and lights disagree.

The fix used the three registered light outputs as the one-hot state. A single sequential block reset to red with 10 remaining, switched lights and loaded the next duration on the edge after count 1, and otherwise decremented. A sampled pedestrian request in green capped the current count at 10 when it was greater than 10. Green entered at 60 and a request held through entry was handled on the next edge while green was active.

Icarus Verilog verified the full 10/60/5 cycle, the request threshold and hold behavior, exclusivity throughout those sequences, and asynchronous reset during green and yellow. The initial test command was rejected by the command runner for recursive shell cleanup. A workspace-local Python TemporaryDirectory ran the same test and cleaned up its files.

This approach applies to controllers whose outputs encode mutually exclusive timed phases and whose phase change must coincide with the timer reload.
