# Width converter output validity

For a valid-only stream packer that emits a word when the current input completes it, check that the registered valid flag and output data update on the same edge. The pre-edge count identifies a word boundary. The input valid signal determines whether the transfer actually happens on that edge. Combining those conditions with OR falsely asserts output validity on ordinary input transfers and on idle cycles at a boundary, when the data register holds its previous value.

In the 24-to-128-bit `TopModule` packer, a continuous MSB-first bit stream completes output words on accepted inputs 6, 11, and 16. Those transfers consume 8, 16, and 24 bits of the current input respectively. After 16 accepted inputs, 384 bits have produced three words, and the four-bit accepted-input counter wraps with no leftover bits. The submitted and supplied fixes both replaced the OR with AND between `valid_in` and the pre-edge count decode for 5, 10, or 15. All 261 grading samples matched with that one-line change.

To verify a converter with unequal widths, model the accepted inputs as a bit queue and remove one output word's worth whenever enough bits accumulate. Insert bubbles immediately before each completion and compare both the valid pulse and the data on the completion edge. Exercise a full count wrap and reset during a partial word so the check covers retained bits and reset behavior.

For slice alignment and the effect of pre-edge sampling, see [Shift-register output timing](shift-register-output-timing.md).

For qualifying state updates with the same transfer that uses them, see [FIFO pointer clocking](fifo-pointer-clocking.md).
