---
name: state-encoding
description: Diagnose duplicate effective state encodings in Verilog or SystemVerilog case-based state machines.
---

# Diagnose state encoding collisions

1. Compare the numeric encodings used by the `case` items and confirm that the state register can represent each one. Consider whether assignment to the register truncates any value.
2. If two states share a value, trace which branch the `case` takes. The first matching item wins in a plain `case`. A transition to the later label can therefore leave the register at the same numeric value and repeatedly select the earlier branch.
3. If the branches already match the specified table, correct the colliding encoding locally. Avoid rewriting the transitions or changing the state machine's reset timing to compensate for an unreachable branch.

In the graded `TopModule.sv` task involving a five-state Moore machine, `S2` and `S3` both encoded `2`. The `S2` branch sent input `1` to `S3`, but the register stayed at `2` and the `S3` branch leading to `S4` was never reached. Changing only the `S3` encoding to `3` passed all 261 grader samples. A local Icarus Verilog simulation also passed all ten state/input pairs and checked the Moore output and active-low reset.
