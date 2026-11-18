# Shift-register output timing

When a detector combines predicates on different slices of a shift register, trace the input bits each predicate sees at the same clock edge. A combinational predicate follows the updated register, while a predicate assigned with a nonblocking assignment at that edge samples the previous register contents. Check both window alignment and output latency. A directed test can drive a known pattern and check the output on the edge that captures its final bit and on the following edge.

In the nine-bit `TopModule` detector for `011XXX110`, the prefix predicate was combinational and the suffix predicate was registered. The graded fix registered the prefix predicate alongside the existing suffix predicate. Both sample the same pre-edge history, so the output asserts one rising edge after the final pattern bit is captured. The submitted fix registered both checks against the next history, including the incoming bit. It passed a local test covering all 512 windows because the test assumed that same timing, but 16 of 237 grading samples differed from the reference.

## Aligning inputs to a registered stage

In the three-input unsigned minimum `TopModule`, the second `slave_mod` sampled the previous cycle's `min(a, b)` alongside the current `c`. The supplied fix changed only `c1` from a combinational assignment to a nonblocking register with a rising-edge clock and active-low asynchronous reset. The second comparator then reads two values captured on the same edge and publishes the minimum on the following rising edge.

The submission made that timing change and renamed the existing `slave_mod` input ports from `a` and `b` to `data_a` and `data_b`. Its Icarus test instantiated only `TopModule` and passed the timing and reset checks. Grading reported a testbench compilation failure and supplied no compiler diagnostic. A named-port instantiation using `.a(...)` and `.b(...)` fails after that rename. When fixing timing in an existing hierarchy, preserve the submodule's established port names unless the repair requires an interface change. Use consecutive input groups with different minima to exercise cycle alignment, and check direct submodule instantiation with the original port names if the patch touches the interface.

## Delaying a flag by one cycle

In the decimal up/down counter `TopModule`, the original combinational `zero` decode asserted in the cycle when `number` reached zero and also asserted on reset release while `number` was still zero. The reference fix moved only `zero` into a rising-edge block with active-low asynchronous reset. On each rising edge out of reset, `zero` samples whether the pre-edge `number` was zero. The submission put the flag and count in one clocked block using nonblocking assignments and matched all 289 grading samples.

For a flag specified for the cycle after a condition, check the edge that creates the condition and the following edge. For example, when counting up, `9 → 0` leaves `zero` low and `0 → 1` raises it. With reset asserted, both outputs clear asynchronously. Releasing reset leaves the flag low until the first rising edge, when it samples the reset count of zero.

For a different sequential output bug involving aliased state constants, see [FSM state encodings](fsm-state-encodings.md).

For a Moore detector that reports on entry to its terminal state and requires an explicit reset override, see [FSM output timing and reset](fsm-output-reset.md).

For RAM and pointer updates that must sample on the same edge, see [FIFO pointer clocking](fifo-pointer-clocking.md).

For a stream packer that must qualify a word boundary with an accepted input, see [Width converter output validity](width-converter-valid.md).

For tracing each datapath input through registered sums, see [Multiplier partial products](multiplier-partial-products.md).
