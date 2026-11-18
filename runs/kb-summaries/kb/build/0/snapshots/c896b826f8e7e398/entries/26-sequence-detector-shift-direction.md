# Shift direction in a registered sequence detector

TopModule detects 011XXX110 with a nine-bit history and two clocked comparisons. The original update put the new sample in bit 8 and retained bits 7:0 in their previous positions, so the input never reached the low bits. The fix shifts the existing bits toward bit 8 and inserts the new sample at bit 0. The prefix and suffix comparisons now see the older and newer samples in stream order.

Both comparisons still read the window before the edge, so they report a match on the edge following the last bit. The register starts at zero and those zeros participate in the initial windows.

A temporary Icarus Verilog bench passed 7,178 cycle checks covering all 512 binary windows, a continuous stream, asynchronous reset, and unknown or high-impedance values in the ignored positions. No alternate implementation was needed.

For serial sequence detectors, trace two consecutive input bits through the shift assignment before changing comparison logic or output timing.
