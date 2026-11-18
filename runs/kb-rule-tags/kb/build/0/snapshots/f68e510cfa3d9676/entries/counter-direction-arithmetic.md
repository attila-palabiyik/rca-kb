For a mode-controlled up/down counter, verify that each mode uses the specified arithmetic operation and wraps at the correct end of the count range.

Applies when a counter selects its direction with a mode input. In the decimal up/down counter `TopModule`, the count-up branch wrapped from 9 to 0 but subtracted one on ordinary updates. Changing that subtraction to addition matched all 289 reference samples.
