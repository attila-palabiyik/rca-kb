When accepting an input beat completes an output word, assert the registered output-valid pulse only when both the input beat is accepted and the pre-edge count marks a word boundary.

Applies to clocked width converters whose input count holds during stalls. In the valid-only `TopModule` converter from 24 to 128 bits, `data_out` already updated only when `valid_in` was high and the pre-edge count was 5, 10, or 15. Changing `valid_out` to use the same conjunction matched all 261 reference samples.
