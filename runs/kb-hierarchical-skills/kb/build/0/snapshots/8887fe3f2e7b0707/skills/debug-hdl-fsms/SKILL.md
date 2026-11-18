---
name: debug-hdl-fsms
description: Debug Verilog and SystemVerilog state machines, sequence detectors, stream width converters, synchronous FIFOs, and pipeline timing.
---

# Debug HDL state machines

- If an expected state is unreachable or an output associated with it never asserts, inspect the [state encodings](state-encoding/SKILL.md) before editing the transition table.
- If the specification gives a transition table, defines counter behavior, or describes consecutive input groups, [check each next-state branch](transition-table/SKILL.md), including exits from states that assert an output.
- For an overlapping sequence detector, check which prefix survives each partial mismatch and each completed match. [Transition table](transition-table/SKILL.md)
- If a sequence detector misses a pattern or reports a match on the wrong cycle, a stream converter misaligns its payload and valid signal, or a pipeline combines operands from different cycles, trace the [registered output timing](registered-output-timing/SKILL.md).
- If a counter exposes both its count and a registered status flag, [check which count each output samples](registered-output-timing/SKILL.md#counter-status-flags).
- If a state timer reloads at the wrong time or two phase outputs assert together, trace its [buffered output assignments and reload conditions](registered-output-timing/SKILL.md#timer-reloads).
- For a clock divider that alternates period lengths, check the [period boundaries and high-pulse widths](registered-output-timing/SKILL.md#fractional-clock-dividers).
- If a fix changes clocked outputs to a combinational state decode, check whether the [outputs need to respond directly to reset](combinational-output-reset/SKILL.md).
- If a synchronous FIFO loses requests, advances a pointer out of step with RAM, or reports incorrect flags after wraparound, check [FIFO enables, pointer timing, and wraparound](fifo-pointer-timing/SKILL.md).
- Verify the repaired path from reset. When the table is small, simulate every state/input pair and check the output and reset at the times required by the specification.
