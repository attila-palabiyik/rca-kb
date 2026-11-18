# Register a status flag specified for the next cycle

In the decimal up/down counter `TopModule`, the original combinational `zero` tracked the current `number` as soon as the count changed. It also asserted on reset release while the count was still zero. The fix registered `zero <= (number == 4'd0)` on the rising clock edge and cleared `zero` on assertion of the active-low asynchronous reset. The comparison samples the count before the edge, so the flag asserts on the edge that leaves zero. The submitted change matched all 289 grading samples, and the reference used the same timing with an explicit `if`/`else` comparison. No alternate fix was tried.

For a flag specified for the cycle after a condition, check both the edge that enters the condition and the following edge. In this counter, check `9 → 0 → 1` when counting up and `1 → 0 → 9` when counting down. Also check that the flag stays low from reset release until the first rising edge, when it samples the reset count of zero.
