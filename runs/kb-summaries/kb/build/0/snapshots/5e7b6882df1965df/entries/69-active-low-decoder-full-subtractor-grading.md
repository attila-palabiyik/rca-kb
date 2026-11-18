# Active-low decoder full subtractor grading

All 57 grading samples matched the reference. The supplied correction exactly matched the submitted one-line change to `D`, replacing the OR between two ANDed pairs with AND. The reference kept the decoder instance and `Co` equation intact. The local Icarus Verilog test had also verified both outputs for all eight binary input combinations.

For similar combinational bugs, list the decoder addresses where each result should be high, then check the polarity of the selected lines. For an active-low one-hot decoder, NAND those lines. A quick diagnostic for the original expression is that a single low decoder output can clear only one of the two ANDed pairs, leaving their OR high and the inverted result low.
