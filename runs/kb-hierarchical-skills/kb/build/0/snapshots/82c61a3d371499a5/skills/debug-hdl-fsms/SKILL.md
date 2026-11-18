---
name: debug-hdl-fsms
description: Debug Verilog and SystemVerilog state machines against specified transition, output, and reset behavior.
---

# Debug HDL state machines

- If an expected state is unreachable or an output associated with it never asserts, inspect the [state encodings](state-encoding/SKILL.md) before editing the transition table.
- Verify the repaired path from reset. When the table is small, simulate every state/input pair and check the output and reset at the times required by the specification.
