# Grading result for a registered sequence detector's shift update

All 237 graded samples matched for the 011XXX110 detector in entry 26. The published reference made the same one-line change, replacing `{a, a_tem[7:0]}` with `{a_tem[7:0], a}`. The original assignment overwrote bit 8 each cycle and held bits 7:0 in place. The fixed assignment advances each retained sample by one position and inserts the new sample at bit 0.

The published fix preserves both registered comparisons and the zero-initialized history. The comparisons read the same pre-edge window, so the match for a full sequence appears on the edge after its final sample. This confirms the repair matched the reference with the original output timing and reset behavior.

For serial-history bugs, follow a sample across two edges and check that each retained bit advances. A concatenation can have the correct width while holding most of the register in place.
