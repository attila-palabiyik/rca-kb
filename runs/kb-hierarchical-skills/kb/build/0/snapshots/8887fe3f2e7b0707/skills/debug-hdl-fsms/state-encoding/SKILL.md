---
name: state-encoding
description: Diagnose duplicate effective state encodings in Verilog or SystemVerilog case-based state machines.
---

# Diagnose state encoding collisions

1. Compare the effective encodings used by the `case` items. Check the width of each literal as well as the width of the state register. A sized literal can truncate before it is assigned to a parameter or compared in a `case`. For example, `4'd20` already has the value `4'd4`.
2. If two states share a value, trace which branch the `case` takes. The first matching item wins in a plain `case`. A transition to the later label can therefore leave the register at the same numeric value and repeatedly select the earlier branch.
3. If the branches already match the specified table, correct the colliding encoding locally. Avoid rewriting the transitions or changing the state machine's reset timing to compensate for an unreachable branch.

In the graded `TopModule.sv` task involving a five-state Moore machine, `S2` and `S3` both encoded `2`. The `S2` branch sent input `1` to `S3`, but the register stayed at `2` and the `S3` branch leading to `S4` was never reached. Changing only the `S3` encoding to `3` passed all 261 grader samples. A local Icarus Verilog simulation also passed all ten state/input pairs and checked the Moore output and active-low reset.

The overlapping `1011` detector had the same `S2`/`S3` collision. Changing only `S3` from `2` to `3` matched all 153 grader samples. Local Icarus Verilog simulation checked all 4,096 twelve-bit streams against a one-cycle-delayed sliding window, verified two pulses for `10110111`, and checked asynchronous reset while `flag` was high. A separate variant of this detector required a transition repair. Check the actual state encodings and branches before applying either fix. [Transition table](../transition-table/SKILL.md)

In the graded nonoverlapping `011100` detector with an out-of-range state literal, `sf6 = 4'd20` collided with `s4 = 4'd4`. The collision caused failed groups to enter the same effective state as a four-bit prefix match, affecting both output decoding and the transition that samples the next group's first bit. The reference changed only `sf6` to the unused encoding `4'd12`. The submission also converted the combinational blocks to wildcard sensitivity and simplified the reset-gated output decode. It matched all 1,215 grader samples. Local Icarus Verilog verification passed all 4,096 ordered pairs of six-bit groups, output timing, and asynchronous reset.
