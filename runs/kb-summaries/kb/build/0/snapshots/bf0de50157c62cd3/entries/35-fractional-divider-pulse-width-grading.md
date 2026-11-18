# Grading result for the fractional divider pulse width

The submitted TopModule matched the reference on all 2,021 grading samples. The reference fixed the waveform by changing only the divide-by-8 comparison, from `clk_cnt <= ((div_e >> 1) + 1)` to `clk_cnt <= ((div_e >> 2) + 1)`. It kept the existing divide-by-9 comparison, which uses the same expression with `div_o`. With the default periods of 8 and 9, both reference comparisons accept counts 0 through 3. The submission's exclusive comparison against half the period accepts those same counts for both defaults.

The expressions can diverge with parameter overrides. A period of 12 gives five high cycles with the reference threshold and six with the submitted threshold. The reference also retained the original fixed counter widths. The custom 130-cycle simulation in entry 34 verified the submitted behavior under its own expected waveform. The grading result establishes agreement on the sampled cases.

For parameterized divider repairs, derive the high-cycle count from both the shift and the inclusive or exclusive comparison. Check pulse widths as well as rising-edge spacing, since an incorrect duty cycle can preserve the average frequency. Distinguish equivalence at the supplied parameter values from equivalence under overrides.
