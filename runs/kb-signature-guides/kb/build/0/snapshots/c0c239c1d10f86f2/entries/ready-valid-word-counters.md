# Ready/valid acceptance and word counters

Applies when a ready/valid receiver's word boundary shifts after idle cycles or on the first clock out of reset. The `TopModule.sv` serial-to-6-bit converter counted cycles that the shift register did not capture.

1. Compare the input capture and counter enables using signal values just before the sampling edge. The shift register captured on `ready_a && valid_a`, so the counter must hold on `!ready_a || !valid_a`. The original hold test used AND between the negated inputs and let the count advance when exactly one handshake signal was high.
2. Exercise both one-high cases. Insert an idle edge with `ready_a=1` and `valid_a=0`, then check that the count and shift register both hold. If ready is registered and cleared on reset, drive `valid_a=1` on the first edge after reset release. The pre-edge `ready_a=0` prevents acceptance even though ready rises after the edge.
3. Trace output data and valid separately with a stall after five accepted bits. In this reference, an edge at count five with `valid_a=0` holds `data_b` and registers `valid_b=1`. When the sixth bit arrives, the output captures the word with the first bit at bit 0 and valid can stay high across that edge. A test that assumes valid strictly marks a data update will reject this behavior.

The supplied correction changed only `~ready_a&&~valid_a` to `~ready_a||~valid_a` in the counter hold test. The submitted rewrite also tied ready high through reset and gated output valid with the sixth accepted bit. Its local scoreboard passed because it expected those changes, but grading reported 16 mismatches out of 151 samples. The grading result did not identify how the mismatches were distributed between the changed behaviors.
