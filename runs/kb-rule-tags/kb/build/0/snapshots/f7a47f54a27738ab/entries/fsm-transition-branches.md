Check both branches of each input-dependent next-state expression against the corresponding row of the transition table, especially when both branches name the same state.

Applies to Verilog/SystemVerilog FSMs with table-specified transitions. In `TopModule`, the S4 branch sent both input values to S1. Changing the `data = 0` destination to S0 matched all 261 reference samples.
