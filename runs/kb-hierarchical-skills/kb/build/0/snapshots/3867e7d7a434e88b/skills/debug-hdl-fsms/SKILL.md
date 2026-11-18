---
name: debug-hdl-fsms
description: Debug Verilog and SystemVerilog state machines, sequence detectors, stream width converters, synchronous FIFOs, and pipeline timing.
---

# Debug HDL state machines

- If an expected state is unreachable or an output associated with it never asserts, inspect the [state encodings](state-encoding/SKILL.md) before editing the transition table.
- If the specification gives a transition table or defines how one input group follows another, [check both input paths from each state](transition-table/SKILL.md), including exits from states that assert an output.
- If a sequence detector misses a pattern or reports a match on the wrong cycle, a stream converter misaligns its payload and valid signal, or a pipeline combines operands from different cycles, trace the [registered output timing](registered-output-timing/SKILL.md).
- If a fix changes clocked outputs to a combinational state decode, check whether the [outputs need to respond directly to reset](combinational-output-reset/SKILL.md).
- If a synchronous FIFO pointer changes between clock edges or appears out of step with the RAM, check [FIFO pointer timing](fifo-pointer-timing/SKILL.md).
- Verify the repaired path from reset. When the table is small, simulate every state/input pair and check the output and reset at the times required by the specification.
