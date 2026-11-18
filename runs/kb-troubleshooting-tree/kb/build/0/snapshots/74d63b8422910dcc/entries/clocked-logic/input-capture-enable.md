# Check which branch captures a valid input

**Check** whether an input register captures new data when the input is accepted and holds its value during invalid cycles. For a ternary assignment, evaluate both branches. If a later clocked assignment consumes the register on an edge that also updates it, trace the value from before that edge.

- **The register captures on invalid cycles and holds on valid cycles.** Correct the branch selection. Exercise consecutive accepted inputs and a pair separated by invalid cycles with changing input data.
- **The register captures on acceptance and holds during invalid cycles.** Trace which saved value the consumer reads on its load edge. If the data and its valid pulse disagree, [check their shared enable](output-valid-enable.md).

**Observed in `TopModule.sv`**, an 8-bit to 16-bit valid-only converter. The byte register held its value when `valid_in` was high and loaded `data_in` when it was low. The reference fix swapped the ternary branches so the register captured every valid byte. The output read the saved first byte before the nonblocking update on the second byte's edge. The submitted fix captured only the first valid byte of each pair and matched all 141 graded samples. The reference fix shows that the pair flag was unnecessary in the byte register's capture enable for this design.
