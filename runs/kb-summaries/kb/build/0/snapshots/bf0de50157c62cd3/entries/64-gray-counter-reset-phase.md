# Gray counter update phase after reset

The four-bit TopModule fed the Gray-encoded output back through a clocked decoder and then a clocked increment. The decoder used blocking assignments, causing a race with the increment stage. Changing the decoder to nonblocking assignments fixed that race, but an Icarus test still saw 0001 on the first rising edge after reset release. The increment stage added one to its reset input of zero on that edge.

The final fix uses an asynchronously reset Gray output register and a phase bit. The Gray feedback wire takes the registered value and therefore starts at zero on reset. Combinational cumulative XOR decodes it, four-bit addition wraps it, and the Gray encoder feeds the output register on every second rising edge. Reset clears the phase bit so the first rising edge holds zero.

An independent Icarus test checks all edge values, one-bit changes including wraparound, asynchronous reset between clocks, and restart cadence. For divided-rate counters, compare the first rising edge after reset release as well as the spacing between subsequent updates.
