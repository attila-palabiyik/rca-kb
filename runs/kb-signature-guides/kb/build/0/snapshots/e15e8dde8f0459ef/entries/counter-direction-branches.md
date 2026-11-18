# Arithmetic in mode-selected counter branches

Applies when a counter moves in the wrong direction for one mode, or when two modes produce the same step away from a wrap boundary.

1. Trace a count strictly between the endpoints for each mode. In a decimal up/down counter, a pre-edge count of 5 should become 6 in up mode and 4 in down mode. Read the arithmetic assignment in each selected branch. A copied subtraction in the up branch makes both modes decrement even when the mode conditions are correct.
2. Check the wrap branches separately. In this design, up from 9 already assigned 0 and down from 0 already assigned 9. A test that checks only those two transitions misses the wrong arithmetic. Stepping up from the reset count of 0 also exposes the error immediately because the ordinary up branch subtracts one and produces 15.
3. Check the flag against the pre-edge count. The original `zero` logic already sampled whether `number` was 0 on the rising edge and cleared asynchronously with `number`. The flag timing and wrap checks required no edits for this bug.

Source task was the decimal up/down counter in `TopModule.sv`. The reference changed only subtraction to addition in the ordinary up branch, keeping `1'd1`. The submitted fix used `4'd1` and matched all 289 grading samples.
