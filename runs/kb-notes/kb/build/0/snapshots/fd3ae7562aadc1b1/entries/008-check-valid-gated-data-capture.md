# Check valid-gated data capture

When a valid-only interface samples data on a clock edge, trace both branches of the input register's enable. With `valid_in` high, capture the input. With `valid_in` low, hold the register. In a clocked block with nonblocking assignments, a packing expression reads the stored byte from before the edge, even when that same edge also updates the byte register.

In the 8-to-16-bit `TopModule`, `valid_in ? data_r : data_in` held the byte register on valid cycles and loaded it on idle cycles. Swapping the two branches fixed the upper byte of each packed word. This one-line change matched the reference on all 141 grading samples. No alternate design fix was tried.

Test two distinct valid bytes on consecutive cycles and again with an idle gap between them. Drive a different byte during the gap so the test can catch an idle-cycle overwrite. Check the full packed word and `valid_out` on each cycle. The Icarus test also checked that reset cleared a pending first byte.
