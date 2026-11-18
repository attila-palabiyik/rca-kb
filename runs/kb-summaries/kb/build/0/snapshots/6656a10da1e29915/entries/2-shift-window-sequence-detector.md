# Aligning a clocked sequence detector's window

TopModule searched for 011XXX110 in a serial stream using a nine-bit shift register. A combinational prefix check used the window after the clock edge while a registered suffix check used the window before that edge. The two checks could therefore produce false positives and miss valid sequences.

The fix registers the conjunction of both checks on the incoming nine-bit window, including the bit sampled at that edge. A saturating count of prior samples keeps match low until nine actual input bits have arrived. With the original zero-initialized shift register, an eight-bit prefix of 11XXX110 would otherwise produce an early match using the reset zero.

A temporary Icarus testbench covered all 512 binary windows, the cycles before each full window, overlapping matches, asynchronous reset, output stability between rising edges, and unknowns in the ignored positions. The first test launch was rejected for its recursive shell cleanup command. The same simulation passed using a workspace-local Python temporary directory.

For shift-register sequence detectors, check which sample window each predicate observes and whether reset values can mimic part of a pattern.
