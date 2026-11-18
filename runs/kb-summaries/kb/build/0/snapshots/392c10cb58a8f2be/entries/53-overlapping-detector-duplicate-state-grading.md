# Grading result for the duplicate state in the overlapping detector

All 153 samples matched the reference. The submitted and reference patches both changed only S3 from 2 to 3. That made the state for prefix 101 distinct from S2, which tracks prefix 10, and allowed the machine to reach S4 and assert its registered flag on the following rising edge.

When an overlapping sequence detector misses a basic match, check that each prefix state has a distinct encoding and trace the first match through the case statement. Once the match state is reachable, verify overlap after a full match and after a partial mismatch, and append a clock sample to observe any delayed pulse.
