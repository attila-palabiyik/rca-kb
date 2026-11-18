# Grading result for the overlapping `1011` detector

All 153 samples matched the reference. The reference and submitted changes both redirected `S3` on input `0` from `S0` to `S2`. This preserves the prefix `10` after `1010` and keeps the flag registered for the rising edge after the final bit.

The supplied overlap example `10110111` already passed before the repair because it exercised the transition after a complete match. The directed stream `101011` exercises the faulty transition after a partial match. When debugging another overlapping detector, include directed inputs for both paths, append a clock for any delayed flag, and compare each cycle with a sliding-window match.
