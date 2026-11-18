# Width converter output validity

For a valid-only stream packer that emits a word when the current input completes it, check that the registered valid flag and output data update on the same edge. The pre-edge count identifies a word boundary. The input valid signal determines whether the transfer actually happens on that edge. Combining those conditions with OR falsely asserts output validity on ordinary input transfers and on idle cycles at a boundary, when the data register holds its previous value.

In the 24-to-128-bit `TopModule` packer, a continuous MSB-first bit stream completes output words on accepted inputs 6, 11, and 16. Those transfers consume 8, 16, and 24 bits of the current input respectively. After 16 accepted inputs, 384 bits have produced three words, and the four-bit accepted-input counter wraps with no leftover bits. The submitted and supplied fixes both replaced the OR with AND between `valid_in` and the pre-edge count decode for 5, 10, or 15. All 261 grading samples matched with that one-line change.

In a separate 24-to-128-bit `TopModule` task, `valid_out` already required `valid_in`, but its middle count comparison used 12 while the `data_out` update used 10. The word loaded on the 11th accepted input had no valid pulse. On the 13th accepted input, the flag asserted while the data register held that same word. Both the submitted and supplied fixes changed only the valid decode from 12 to 10, and all 261 grading samples matched. Even when the flag has the correct input-valid gating, compare every count literal in its boundary decode against the data register's update conditions.

To verify a converter with unequal widths, model the accepted inputs as a bit queue and remove one output word's worth whenever enough bits accumulate. Insert bubbles immediately before each completion and compare both the valid pulse and the data on the completion edge. Exercise a full count wrap and reset during a partial word so the check covers retained bits and reset behavior.

In the 8-to-16-bit `TopModule` packer, the output enable already correctly used the pre-edge pair flag and `valid_in`. The byte register's mux had its branches reversed, so it held stale data on valid inputs and captured invalid bus values during idle cycles. The supplied fix captured `data_in` on every valid input and held the register during idle cycles. The submitted fix captured only the first valid byte of each pair and matched all 141 grading samples. Capture on every valid input works because the output register reads the pre-edge byte register on the second transfer, before the nonblocking update replaces its contents. The next pair's first transfer then refreshes the register before it is read again.

When output validity is correct but the high byte of a pair is wrong, trace the saved byte through the first accepted transfer, any intervening idle cycles, and the second accepted transfer. Drive different bus values during idle cycles to expose an inverted capture enable, and use distinct bytes in consecutive pairs to verify the order and pairing.

For slice alignment and the effect of pre-edge sampling, see [Shift-register output timing](shift-register-output-timing.md).

For qualifying state updates with the same transfer that uses them, see [FIFO pointer clocking](fifo-pointer-clocking.md).
