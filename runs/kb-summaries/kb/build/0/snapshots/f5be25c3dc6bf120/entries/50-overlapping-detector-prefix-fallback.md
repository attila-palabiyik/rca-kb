# Retaining a prefix after a partial sequence mismatch

TopModule detects `1011` and registers its flag on the rising edge after the final bit. A zero after the matched prefix `101` sent the FSM to the idle state. The stream `101011` then missed the occurrence starting at the third bit, even though the supplied example `10110111` already worked.

Changed the zero-input transition from the `101` state to the `10` state because `10` is the longest suffix of `1010` that is a prefix of `1011`. Icarus Verilog passed both directed streams, asynchronous reset with the flag high, and all 4,096 twelve-bit streams with a trailing clock to check the last possible match. The repair required one transition change.

For overlapping sequence detectors, check the longest prefix that survives each mismatch as well as each transition after a complete match.
