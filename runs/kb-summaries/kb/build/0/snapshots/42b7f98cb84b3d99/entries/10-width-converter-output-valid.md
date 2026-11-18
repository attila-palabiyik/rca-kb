# Qualifying a width converter's output valid

TopModule packs a stream of 24-bit inputs into 128-bit words, oldest bits first. Six, eleven, and sixteen accepted inputs within each sixteen-input period complete output words. The original datapath already selected the required slices and retained any bits for the next word. The output-valid expression used OR, so it asserted on every accepted input and during pauses at completion counts.

The fix qualifies the three completion counts with valid_in using AND. This makes the registered flag follow the existing registered data update, including when a pause holds the count at a completion boundary. The datapath, counter, and asynchronous reset behavior were preserved.

An independent Icarus Verilog bit-stream scoreboard passed 1,159 cycles and verified 166 output words, including continuous input, gaps at all three boundaries, randomized valid patterns, and reset with a partially filled word. The first testbench run left valid_in high across a reset release and missed an accepted edge. Driving valid_in low before reset fixed the testbench.

For similar valid-only width converters, compare the output-valid condition to the data register's write condition and account for leftover bits at noninteger width ratios.
