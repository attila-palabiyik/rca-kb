# Aligning the second output-valid pulse in a 24-to-128-bit converter

TopModule packs accepted 24-bit inputs into a continuous stream of 128-bit outputs, with earlier bits in the high positions. The Icarus Verilog scoreboard first failed on accepted input 11, when the second completed word had no valid pulse. The data register captured at counter values 5, 10, and 15, but the valid register used 12 in place of 10. The counter is zero-based and wraps after 16 accepted inputs.

Changed the valid comparison from 12 to 10. The same scoreboard then checked 150 output words across 805 accepted inputs, including idle gaps at completion boundaries, randomized valid cycles, and reset with a partial word pending. No datapath change or alternate fix was needed.

For similar width-converter tasks, calculate completion from the number of accepted bits and check that valid and data update at the same counter values.
