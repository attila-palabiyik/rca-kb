When converting registered FSM outputs to a combinational state decode, retain an explicit reset override if the outputs must take defined values while reset is asserted.

Applies to Verilog/SystemVerilog FSMs with asynchronous reset. In the `TopModule` detector for `011100`, decoding only the current state and relying on its reset value passed directed simulation but differed from the reference on 1 of 1215 samples. The reference explicitly forced both outputs low while reset was asserted. The grading report did not identify the failing sample.
