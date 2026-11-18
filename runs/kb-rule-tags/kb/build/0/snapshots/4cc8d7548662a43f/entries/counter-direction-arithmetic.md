For a mode-controlled up/down counter, verify each mode's arithmetic and compare the current count against the highest legal value when counting up and the lowest legal value when counting down to decide when to wrap.

Applies when a counter selects its direction with a mode input. In the decimal up/down counter `TopModule`, the count-up branch wrapped from 9 to 0 but subtracted one on ordinary updates. Changing that subtraction to addition matched all 289 reference samples.

In another decimal up/down counter `TopModule` variant, the count-up branch checked for 10 before wrapping, so the counter output included 10. The reference changed only the comparison to 9. The submitted fix also sized the comparison and wrap literals to four bits and matched all 289 reference samples.
