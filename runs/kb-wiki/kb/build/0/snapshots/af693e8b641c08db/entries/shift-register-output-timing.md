# Shift-register output timing

When a detector combines predicates on different slices of a shift register, trace the input bits each predicate sees at the same clock edge. A combinational predicate follows the updated register, while a predicate assigned with a nonblocking assignment at that edge samples the previous register contents. Check both window alignment and output latency. A directed test can drive a known pattern and check the output on the edge that captures its final bit and on the following edge.

## Checking shift direction, pattern constants, and sample edges

Trace where the newest bit goes and how each stored bit moves on the next edge. When a detector reads the oldest bits at the high end of the register, append the incoming bit at the low end and move each retained bit up one position.

In the nine-bit `TopModule` detector for `011XXX110` with a faulty shift assignment, `{a, a_tem[7:0]}` overwrote bit 8 on every edge and held bits 7 through 0 at their previous values. After reset those lower bits stayed zero, so the suffix could never become `110`. Both the submitted fix and the reference used `{a_tem[7:0], a}` as the sole change. All 237 grading samples matched. The registered prefix and suffix checks still read the pre-edge window, so `match` asserts one rising edge after capture of the final bit. Local Icarus checks covered all 512 windows, overlapping detections, and asynchronous reset while `match` was high.

In one nine-bit `TopModule` detector for `011XXX110`, the prefix predicate was combinational and the suffix predicate was registered. The graded fix registered the prefix predicate alongside the existing suffix predicate. Both sample the same pre-edge history, so the output asserts one rising edge after the final pattern bit is captured. The submitted fix registered both checks against the next history, including the incoming bit. It passed a local test covering all 512 windows because the test assumed that same timing, but 16 of 237 grading samples differed from the reference.

In a second nine-bit `TopModule` task for the same pattern, both predicates already sampled the same pre-edge history. The prefix comparison used `3'b001` for bits `[8:6]` where the pattern required `3'b011`. Changing that literal alone matched the supplied fix and all 237 grading samples. The suffix comparison used `3'b110` for bits `[2:0]`, and `match` asserted one rising edge after capture of the final bit. An Icarus test covered all 512 windows, including all eight middle-bit combinations that should match, plus overlapping matches and asynchronous reset while `match` was high.

Check the fixed bit values and their sample edges independently. In an exhaustive window test, calculate the expected comparison from the pre-edge history when the registered output samples that history. A test that covers every window can still miss a latency error if its expected output uses the same sample edge as the faulty implementation.

## Aligning inputs to a registered stage

In the three-input unsigned minimum `TopModule`, the second `slave_mod` sampled the previous cycle's `min(a, b)` alongside the current `c`. The supplied fix changed only `c1` from a combinational assignment to a nonblocking register with a rising-edge clock and active-low asynchronous reset. The second comparator then reads two values captured on the same edge and publishes the minimum on the following rising edge.

The submission made that timing change and renamed the existing `slave_mod` input ports from `a` and `b` to `data_a` and `data_b`. Its Icarus test instantiated only `TopModule` and passed the timing and reset checks. Grading reported a testbench compilation failure and supplied no compiler diagnostic. A named-port instantiation using `.a(...)` and `.b(...)` fails after that rename. When fixing timing in an existing hierarchy, preserve the submodule's established port names unless the repair requires an interface change. Use consecutive input groups with different minima to exercise cycle alignment, and check direct submodule instantiation with the original port names if the patch touches the interface.

## Delaying a flag by one cycle

In the decimal up/down counter `TopModule`, the original combinational `zero` decode asserted in the cycle when `number` reached zero and also asserted on reset release while `number` was still zero. The reference fix moved only `zero` into a rising-edge block with active-low asynchronous reset. On each rising edge out of reset, `zero` samples whether the pre-edge `number` was zero. The submission put the flag and count in one clocked block using nonblocking assignments and matched all 289 grading samples.

For a flag specified for the cycle after a condition, check the edge that creates the condition and the following edge. For example, when counting up, `9 → 0` leaves `zero` low and `0 → 1` raises it. With reset asserted, both outputs clear asynchronously. Releasing reset leaves the flag low until the first rising edge, when it samples the reset count of zero.

In a separate decimal up/down `TopModule` task, `zero` already sampled the pre-edge count and both wraparound branches were correct. The ordinary update in the up branch subtracted one. The reference changed only `- 1'd1` to `+ 1'd1`. The submission used `+ 4'd1` and matched all 289 grading samples. Check an ordinary step and a wraparound in each mode as well as the flag timing. Testing the up branch at 9 alone would exercise the correct wraparound and miss the wrong operator.

For a different sequential output bug involving aliased state constants, see [FSM state encodings](fsm-state-encodings.md).

For a Moore detector that reports on entry to its terminal state and requires an explicit reset override, see [FSM output timing and reset](fsm-output-reset.md).

For RAM and pointer updates that must sample on the same edge, see [FIFO pointer clocking](fifo-pointer-clocking.md).

For a stream packer whose valid flag must sample the same word boundary as the data register, see [Width converter output validity](width-converter-valid.md#align-valid-and-data-on-the-same-edge).

For checking whether a final sum has its own pipeline stage, see [Multiplier partial products](multiplier-partial-products.md#check-the-final-sums-clock-edge).

For a counter with a faulty Gray-to-binary dependency, see [Gray code conversion](gray-code-conversion.md).

For a registered clock divider output whose pulse width can be wrong even when the period schedule is correct, see [Fractional divider duty cycle](fractional-divider-duty-cycle.md).
