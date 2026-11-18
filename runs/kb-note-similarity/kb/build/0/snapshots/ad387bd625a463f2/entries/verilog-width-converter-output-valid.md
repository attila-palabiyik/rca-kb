# Assert registered output valid when the output word updates

In the 24-bit to 128-bit `TopModule` width converter, `data_out` loaded on a rising edge only when `valid_in` was high and the pre-edge input counter was 5, 10, or 15. The original `valid_out` combined those conditions with OR, asserting for valid inputs that did not complete a word and for idle cycles stalled at a completion count.

The submitted fix changed OR to AND so the registered valid flag used the same condition as the data load. It matched all 261 graded samples, and the reference made the equivalent one-line change. The existing slices packed the stream MSB first, taking 8, 16, and 24 bits from the input that completed each successive output word in the 16-input cycle.

For a valid-only interface with registered data and valid, trace the data register's write condition before changing the counter or datapath. Test continuous input for early valid pulses and insert idle cycles immediately before each word-completing input to catch valid pulses when the counter stalls at a completion value. Check data and valid together after each sampling edge.
