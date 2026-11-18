---
name: debug-hdl-fsms
description: Debug Verilog and SystemVerilog state machines and sequence detectors against specified transition, output, and reset behavior.
---

# Debug HDL state machines

- If an expected state is unreachable or an output associated with it never asserts, inspect the [state encodings](state-encoding/SKILL.md) before editing the transition table.
- If a sequence detector combines combinational and clocked checks or reports matches on the wrong cycle, trace the [registered output timing](registered-output-timing/SKILL.md).
- Verify the repaired path from reset. When the table is small, simulate every state/input pair and check the output and reset at the times required by the specification.
