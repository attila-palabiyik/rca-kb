# Incorrect low-input transition out of a Moore terminal state

TopModule implemented a five-state Moore FSM with a clocked state register and a combinational block for next state and flag. The transition table specified S4 to S1 on high data and S4 to S0 on low data. Both branches in the original S4 case selected S1, so low data after reaching S4 incorrectly advanced the next detection.

Changing the low-data branch to S0 fixed the transition. An Icarus Verilog testbench passed all ten state/input transitions, checked that flag followed only the registered state when data changed between edges, and verified asynchronous active-low reset from S4. There were no failed implementation attempts.

For an FSM with a transition table, check both inputs in every state, including exit from the state that asserts the output.
