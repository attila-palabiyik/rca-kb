# Width converter output validity

For a valid-only stream packer that emits a word when the current input completes it, check that the registered valid flag and output data update on the same edge. The pre-edge count identifies a word boundary. The input valid signal determines whether the transfer actually happens on that edge. Combining those conditions with OR falsely asserts output validity on ordinary input transfers and on idle cycles at a boundary, when the data register holds its previous value.

In the 24-to-128-bit `TopModule` packer, a continuous MSB-first bit stream completes output words on accepted inputs 6, 11, and 16. Those transfers consume 8, 16, and 24 bits of the current input respectively. After 16 accepted inputs, 384 bits have produced three words, and the four-bit accepted-input counter wraps with no leftover bits. The submitted and supplied fixes both replaced the OR with AND between `valid_in` and the pre-edge count decode for 5, 10, or 15. All 261 grading samples matched with that one-line change.

In a separate 24-to-128-bit `TopModule` task, `valid_out` already required `valid_in`, but its middle count comparison used 12 while the `data_out` update used 10. The word loaded on the 11th accepted input had no valid pulse. On the 13th accepted input, the flag asserted while the data register held that same word. Both the submitted and supplied fixes changed only the valid decode from 12 to 10, and all 261 grading samples matched. Even when the flag has the correct input-valid gating, compare every count literal in its boundary decode against the data register's update conditions.

## Align valid and data on the same edge

In the 24-to-128-bit `TopModule` task with combinational `valid_out`, the count comparisons and `valid_in` gating were already correct. At a word boundary the combinational flag could assert before the rising edge while `data_out` still held its previous value. After the edge, the counter advanced and the decode deasserted as the new word appeared. The submitted and supplied fixes moved only `valid_out` into a rising-edge block with active-low asynchronous reset and nonblocking assignments. The block samples the same pre-edge count and input valid as the data register. All 261 grading samples matched.

When the boundary expression already agrees with the data update enable, compare their sampling times. Drive `valid_in` between rising edges at a word boundary and check that both outputs hold until the edge. Then check that valid and the new word appear together and that valid clears on the following idle edge. An Icarus bit-stream scoreboard checked 84 output words in this task, with idle cycles at each boundary, counter wraparound, and reset during a partial word.

To verify a converter with unequal widths, model the accepted inputs as a bit queue and remove one output word's worth whenever enough bits accumulate. Insert bubbles immediately before each completion and compare both the valid pulse and the data on the completion edge. Exercise a full count wrap and reset during a partial word so the check covers retained bits and reset behavior.

## Check partial-word capture

In the 8-to-16-bit `TopModule` packer, the output enable already correctly used the pre-edge pair flag and `valid_in`. The byte register's mux had its branches reversed, so it held stale data on valid inputs and captured invalid bus values during idle cycles. The supplied fix captured `data_in` on every valid input and held the register during idle cycles. The submitted fix captured only the first valid byte of each pair and matched all 141 grading samples. Capture on every valid input works because the output register reads the pre-edge byte register on the second transfer, before the nonblocking update replaces its contents. The next pair's first transfer then refreshes the register before it is read again.

When output validity is correct but the high byte of a pair is wrong, trace the saved byte through the first accepted transfer, any intervening idle cycles, and the second accepted transfer. Drive different bus values during idle cycles to expose an inverted capture enable, and use distinct bytes in consecutive pairs to verify the order and pairing.

In a separate 8-to-16-bit `TopModule` task, `data_r` used a self-holding combinational block that followed `data_in` whenever `valid_in` was high. The second byte could overwrite the saved first byte before the output sampled it, even with the correct output enable. The supplied fix moved `data_r` to a rising-edge block with active-low asynchronous reset and nonblocking assignments, capturing every valid byte. The submission used the same clock and reset and captured only when `valid_in && !flag`, where `flag` marks a pending first byte. All 141 grading samples matched. Capturing every valid byte also works because the output register reads the pre-edge value of `data_r` on the second transfer.

To expose a transparent saved-byte latch, present two distinct bytes on consecutive rising edges with `valid_in` continuously high. Check that the word after the second edge contains the first byte in the high bits. Repeat with an idle gap and reset during a partial pair. See [Shift-register output timing](shift-register-output-timing.md#aligning-inputs-to-a-registered-stage) for another case where registering an input aligns the samples seen by a downstream stage.

## Count accepted input transfers

In the 1-to-6-bit serial-to-parallel `TopModule`, the shift register already updated on `ready_a && valid_a`. The counter held only when both signals were low, so it advanced during a stall whenever exactly one signal was high. The supplied fix changed the hold condition from `~ready_a && ~valid_a` to `~ready_a || ~valid_a`. This gives the counter the same transfer enable as the shift register, including when the count wraps from five to zero.

The submission also tied `ready_a` high and gated the registered `valid_b` with `valid_a`. Its Icarus test passed all 64 data patterns, idle cycles, consecutive words, and reset during a partial word, but grading reported 16 mismatches out of 151 samples. The reference retained the original `ready_a` register and `valid_b <= cnt == 5` decode. With that decode, a stall at count five can assert `valid_b` while `data_b` holds its previous word. That behavior differs from the completion-pulse assumption encoded in the local test. The grading report did not identify which samples differed.

When diagnosing a counter enable, check that it agrees with the input data capture enable for all four ready/valid combinations. For a targeted repair, check existing interface timing separately before changing it. In this design, sample `ready_a` during reset and before the first rising edge after reset release, then sample `valid_b` on a stalled edge at count five and on the completion edge.

## Check that the counter reaches the output boundary

In a separate 1-to-6-bit serial-to-parallel `TopModule` task, the counter already held when either `ready_a` or `valid_a` was low. It wrapped at four, so the fifth accepted bit returned it to zero and the count-five output decodes were unreachable. The supplied fix changed only the wrap comparison from four to five. The fifth accepted bit now leaves the count at five, and the sixth loads `data_b` and wraps the count to zero. The shift direction already put the first bit in bit 0.

The submission also tied `ready_a` high and qualified `valid_b` with `valid_a`. Its Icarus scoreboard passed all 64 data patterns, stalls, continuous transfers, and reset, but 16 of 151 grading samples differed. The supplied reference kept `ready_a` low during reset and until the first rising edge after release. Its registered `valid_b` sampled `cnt == 5`, so an idle edge at count five could assert the flag while `data_b` held its previous word. The grading report gave only the total mismatch count.

Trace the pre-edge count across the last two accepted transfers and compare the wrap threshold with the count used to load the output word. To verify a threshold-only repair, include consecutive words, an idle edge at the terminal count, and a valid input on the first rising edge after reset release. Use the existing output logic to derive the expected timing on those boundary cycles.

For a similar check that two operations use the same terminal count, see [FIFO pointer clocking](fifo-pointer-clocking.md#check-that-the-wrap-bit-toggles-with-the-address).

For slice alignment and the effect of pre-edge sampling, see [Shift-register output timing](shift-register-output-timing.md).

For checking an enable shared by a memory transfer and its pointer update, see [FIFO pointer clocking](fifo-pointer-clocking.md#check-the-enable-polarity).
