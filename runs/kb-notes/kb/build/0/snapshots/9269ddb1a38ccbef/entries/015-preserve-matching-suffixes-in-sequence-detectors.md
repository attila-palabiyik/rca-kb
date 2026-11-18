# Preserve matching suffixes in sequence detectors

For an overlapping sequence detector, derive each transition from the longest suffix of the matched prefix plus the new bit that is also a prefix of the target. Check this after a mismatch as well as after a complete match. An overlap example can exercise the transition out of the match state and miss a broken fallback from a partial match.

In the `1011` detector `TopModule`, `S3` represented `101`. A following zero formed `1010`, whose longest matching suffix is `10`, represented by `S2`. The submission and reference changed only the zero arm of `S3` from `S0` to `S2`. All 153 grading samples matched. No alternative patch was tried.

The Icarus test checked `1010110` for the partial-match fallback and `10110111` for two overlapping matches. It also compared all 4,096 12-bit streams with a sliding-window check at the existing one-clock output delay. When testing a registered detector, feed a trailing sample so a match ending at the end of the test stream can produce its pulse.
