# Check valid-gated data capture

When a valid-only interface samples data on a clock edge, check that the storage is edge-triggered and trace both branches of its enable. Capture valid beats required for later cycles and hold the register through idle cycles. In a clocked block with nonblocking assignments, a packing expression reads the stored byte from before the edge, even when that same edge also updates the byte register.

Two 8-to-16-bit `TopModule` tasks exposed different bugs in the first-byte storage.

- One version held its clocked register on valid cycles and loaded it on idle cycles. Swapping the two branches of `valid_in ? data_r : data_in` matched all 141 grading samples.
- Another version used `always @(*)` with self-feedback for storage. When `valid_in` stayed high, the latch could follow the second byte before the packing edge, losing the first byte. Replacing it with a rising-edge register with asynchronous reset, enabled only on the first valid byte of each pair, matched all 141 grading samples. The supplied reference captured on every valid edge. Both forms preserve the first byte for the packing expression because it reads the pre-edge register value. No intermediate fix was tried.

Test two distinct valid bytes on consecutive cycles and again with an idle gap between them. Drive a different byte during the gap so the test can catch an idle-cycle overwrite. Check the full packed word and `valid_out` on each cycle. Icarus checks also verified consecutive pairs and reset with a pending first byte.
