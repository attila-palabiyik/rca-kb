# Decimal up/down counter delayed zero flag

TopModule's decimal count wrapped correctly, but its combinational zero flag asserted during the count of zero and immediately on reset release. The specification called for the flag during the following cycle.

The fix clocks zero on the rising edge and clears it on asynchronous active-low reset. A nonblocking assignment samples whether number was zero before the clock edge. The existing counter transitions were preserved.

An independent Icarus Verilog simulation passed up and down wraparound, direction changes, delayed assertion, reset between clock edges with the flag high, and reset release before the first clock. There were no failed RTL attempts. A Git diff check was unavailable because the workspace was not a Git repository.

For similar RTL tasks, distinguish a combinational state decode from a registered flag by checking both the edge that enters the state and the edge that leaves it. Check reset release before a clock edge, especially when the reset state itself satisfies the flag condition.
