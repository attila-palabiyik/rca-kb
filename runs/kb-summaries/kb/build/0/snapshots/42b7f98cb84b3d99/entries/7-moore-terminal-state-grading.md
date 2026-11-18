# Grading result for the Moore FSM terminal-state transition

This follows entry 6. In the five-state TopModule Moore FSM, both branches of the S4 transition selected S1. As a result, low data in S4 left the machine in S1 on the next rising clock edge, one state ahead of the specified S0. In either state, flag was already low, so an output-only test needs subsequent clocks to expose the incorrect transition.

The submitted one-line change, `next_state = data ? S1 : S0;`, exactly matched the reference patch. All 261 grading samples matched the reference.

For similar FSM bugs, test input history far enough beyond the suspect transition for different destination states to produce different outputs. In this design, four consecutive ones followed by a zero and three more ones distinguish the two branches by flag on the last clock.
