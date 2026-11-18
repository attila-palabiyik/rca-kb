Check that the shift-register assignment inserts each new sample at the end the decoder treats as newest and advances every retained sample one position toward the oldest end.

Applies to serial sequence detectors that compare fixed register slices. In the `TopModule` detector for `011XXX110`, `{a, a_tem[7:0]}` only overwrote bit 8, leaving bits 7:0 unchanged. Using `{a_tem[7:0], a}` put the newest bit at bit 0 and advanced the retained history toward bit 8. This single change matched all 237 reference samples with the existing reset and registered comparisons.
