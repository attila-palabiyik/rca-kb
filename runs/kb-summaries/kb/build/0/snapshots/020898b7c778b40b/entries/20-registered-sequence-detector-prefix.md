# Incorrect prefix in a registered shift-window detector

TopModule used a nine-bit shift register and two registered comparisons to detect `011XXX110`. The prefix comparator checked `a_tem[8:6] == 3'b001`, so the circuit accepted the wrong prefix and missed valid windows. The suffix comparison already checked `a_tem[2:0] == 3'b110`. The only edit changed the prefix literal to `3'b011`. All 237 graded samples matched, and the published reference made the same one-line change.

Both comparisons sample the pre-edge shift register. A match therefore appears on the rising edge after the final bit is shifted in. Icarus Verilog passed 5,130 cycle checks covering all 512 binary windows and verified that asserting active-low reset asynchronously clears an active match.

For shift-register detector repairs, trace which window each comparison samples before changing the timing. When both comparisons already sample the same window, verify the bit order and the literals first. Entry 3 covers a similar detector whose comparisons originally sampled different windows.
