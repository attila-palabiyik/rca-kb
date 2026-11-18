# Check suffix fallback in overlapping sequence detectors

**Check** each transition that follows a partial match or a full match. Append the incoming bit to the pattern prefix represented by the current state. Find the longest suffix of that result that is also a prefix of the target pattern, and compare it with the match length represented by the destination state.

- **The lengths differ.** Correct the transition and follow it with enough bits to complete the match from the retained suffix. Check the pulse at the specified clock edge using the [registered output timing check](transition-output-timing.md).
- **The lengths agree on every transition.** Continue with the [registered output timing check](transition-output-timing.md).

**Observed in `TopModule.sv`**, an overlapping `1011` detector. When `S3` had matched `101` and sampled `0`, the resulting `1010` retained the suffix `10`, so the fallback belonged in `S2`. Changing that branch from `S0` to `S2` matched all 153 grading samples and was the reference fix. The supplied overlap example, `10110111`, exercises fallback after a full match and never takes the faulty branch. The stream `101011` exercises the partial-match fallback and completes a match on its final bit. Clock one more bit to observe the registered pulse.
