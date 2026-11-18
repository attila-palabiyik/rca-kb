# Check which cycle an output flag reports

**Check** the flag immediately after an edge that makes its predicate true and again after the next edge, when the predicate goes false. A combinational flag follows the updated value. A flag assigned in a clocked block using a nonblocking assignment samples the pre-edge value of the register it reads.

- **The flag should report the predicate on the following cycle.** Register the comparison against the current value using the same clock edge as the source register. If reset explicitly clears the flag, give reset priority over the comparison. Check flag timing across both reset assertion and release when the source register's reset value satisfies the predicate.
- **The flag should reflect the current cycle.** If it agrees with the updated value, conclude that a one-cycle delay would be incorrect and check the predicate and reset behavior if the flag still fails.

**Observed in `TopModule.sv`**, a decimal up/down counter. The original combinational `zero` followed the current `number` and asserted as soon as reset was released while `number` was 0. The reference fix registered `number == 0` and asynchronously cleared `zero`. Thus `zero` stayed low when the count entered 0 from a nonzero value and went high at the next rising edge, when the count left 0. Reset release also left `zero` low until the first rising edge, which sampled the reset count of 0. The submitted implementation placed both assignments in one clocked block and matched all 289 graded samples.
