Check that each state has a distinct encoding when a case-based FSM fails to advance despite matching the transition table.

Applies to Verilog/SystemVerilog FSMs with explicit state constants. In TopModule, S2 and S3 both encoded 2, so the S2 case arm won and S4 was unreachable from reset. Changing only S3 to 3 matched all 261 reference samples.
