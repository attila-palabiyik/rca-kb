# Check the enable shared by registered data and valid

**Check** whether a registered valid pulse uses the same pre-edge condition as the update that loads its output word. Compare the full set of counter or state values that trigger each update and the input-valid guard.

- **The conditions differ.** If the interface calls for a valid pulse when a new word is loaded, align the valid condition with the data load. Exercise both cases where the conditions can disagree. Accept an input before the word is complete, then stall on an edge where the next accepted input would complete a word. Neither edge should assert output valid. Resume input and verify that the word and valid pulse appear together.
- **The conditions agree.** If the pulse is early or late, [check which cycle the conditions sample](combined-condition-timing.md). If the pulse timing is correct but the word is wrong, trace the data slices used on the load edge.

**Observed in `TopModule.sv`**, a 24-bit to 128-bit stream converter. The data register loaded a word when the pre-edge count was 5, 10, or 15 and `valid_in` was high. The valid register combined the count match and `valid_in` with OR, allowing pulses on ordinary input beats and during stalls at a completion count. The reference fix changed OR to AND. The submitted implementation also reorganized the clocked logic and narrowed the shift register from 128 to 120 bits. It matched all 261 graded samples. The reference diff shows that the valid expression alone was sufficient.

**Observed in another `TopModule.sv` task for the same width converter**, the input-valid guard and two completion counts agreed, but `valid_out` used count 12 where `data_out` used count 10. With a valid input at count 10, the word loaded without a valid pulse. At count 12, valid asserted while the data register held its previous word. Changing 12 to 10 in the valid expression matched all 261 graded samples and was the complete reference fix.
