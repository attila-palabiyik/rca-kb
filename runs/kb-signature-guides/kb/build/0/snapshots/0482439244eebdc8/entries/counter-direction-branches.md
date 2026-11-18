# Arithmetic in mode-selected counter branches

Applies when a counter moves in the wrong direction for one mode, or when two modes produce the same step away from a wrap boundary.

1. Trace a count strictly between the endpoints for each mode. In a decimal up/down counter, a pre-edge count of 5 should become 6 in up mode and 4 in down mode. Read the arithmetic assignment in each selected branch. A copied subtraction in the up branch makes both modes decrement even when the mode conditions are correct.
2. Check the wrap branches separately. In this design, up from 9 already assigned 0 and down from 0 already assigned 9. A test that checks only those two transitions misses the wrong arithmetic. Stepping up from the reset count of 0 also exposes the error immediately because the ordinary up branch subtracts one and produces 15.
3. Check the flag against the pre-edge count. The original `zero` logic already sampled whether `number` was 0 on the rising edge and cleared asynchronously with `number`. The flag timing and wrap checks required no edits for this bug.

Source task was the decimal up/down counter in `TopModule.sv`. The reference changed only subtraction to addition in the ordinary up branch, keeping `1'd1`. The submitted fix used `4'd1` and matched all 289 grading samples.

## Off-by-one wrap threshold

Applies when the counter steps correctly within its range but visits a value beyond an endpoint before wrapping.

1. Trace the edge from the last legal count in the failing direction. In the decimal counter, the up branch compared the pre-edge `number` against `10`. At `9` the guard was false, so the ordinary increment produced `10` for a full cycle. The wrap guard must match the last legal count, `9`.
2. Check an interior step in each mode and the opposite wrap. In this variant, `5` advanced to `6` in up mode and to `4` in down mode, and down mode wrapped from `0` to `9`. Those checks isolated the up-mode wrap guard.
3. Check the flag across the wrap. With consecutive up-count edges, the corrected post-edge `(number, zero)` pairs are `(9, 0)`, `(0, 0)`, `(1, 1)`, and `(2, 0)`. The existing flag register samples the pre-edge count and clears asynchronously with the counter.

Source task was a separate decimal up/down counter bug in `TopModule.sv`. The reference changed the up-mode comparison from `10` to `9`. The submitted fix also used explicit four-bit literals for the comparison and the wrap value. All 289 grading samples matched.
