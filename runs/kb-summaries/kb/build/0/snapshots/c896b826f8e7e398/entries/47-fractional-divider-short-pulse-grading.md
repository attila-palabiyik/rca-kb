# Fractional divider short pulse grading

The submitted TopModule passed all 2,021 graded samples. The supplied reference fix changes a single shift in the divide-by-8 branch from three bits to two and preserves the inclusive comparison. For period 8, this increases the number of high input cycles from three to four. The divide-by-9 branch already produces four high cycles. The default schedule gives ten output cycles per 87 input cycles.

The submitted fix used an exclusive comparison against half the period, rounded down, in both branches and derived the counter widths from the parameters. That produces the same default waveform as the reference fix. The local Icarus test also passed using periods of 18 and 19 with the submitted formula. The formulas differ for some overrides. For example, period 12 gives five high cycles with the reference formula and six with the submitted formula. The grading result establishes agreement on the sampled behavior.

For related counter-based waveform bugs, calculate the number of counter values accepted by each bound, including the zero count. Check high and low pulse widths independently of average frequency, and test override behavior separately when changing a parameterized formula.
