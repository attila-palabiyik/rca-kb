# Grading result for the 24-to-128-bit width converter

The submitted TopModule matched the reference on all 261 grading samples. Both fixes changed only the registered valid_out expression. The reference ANDed valid_in with the existing comparisons for counts 5, 10, and 15. The submission used the same conjunction with valid_in first and explicitly sized four-bit count literals.

For similar registered valid-only interfaces, compare the valid flag's assertion condition with the data register's write enable. This circuit requires both an accepted input and a word boundary. Check a valid input before a boundary and an idle cycle while the counter is held at a boundary. Each case independently exposes the erroneous OR.
