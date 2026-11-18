# Decimal up/down counter wraps at nine

TopModule compared the up-count against 10, so it exposed 10 for a cycle after 9. The fix compares against `4'd9` and loads `4'd0` at that edge. The existing registered zero flag samples the count before each edge and clears on asynchronous reset.

An independent Icarus Verilog test passed both wrap directions, mode changes, the delayed zero flag, and asynchronous reset while the flag was high. The first test command was rejected before simulation because it used recursive cleanup. Unlinking each temporary file and removing the empty directory resolved that issue. No alternate RTL change was needed.

For bounded counter tasks, check the transition from the highest legal count and sample status flags before and after the edge that changes the count.
