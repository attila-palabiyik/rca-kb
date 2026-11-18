In a registered valid-only width converter, use the same accepted-beat condition and pre-edge boundary checks for the output-valid pulse and the output data update.

Applies to clocked width converters whose input count holds during stalls. In the 24-to-128-bit `TopModule` converter, `data_out` updated on valid input at counts 5, 10, and 15, while `valid_out` checked 12 for the middle boundary. Changing that literal from 12 to 10 matched all 261 reference samples.
