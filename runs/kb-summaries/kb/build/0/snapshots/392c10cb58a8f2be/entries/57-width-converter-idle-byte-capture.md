# Capturing a valid first byte across idle cycles

TopModule packs two valid 8-bit inputs into one 16-bit word and asserts a registered output-valid pulse. The first-byte register sampled the input bus on idle cycles. In a directed Icarus Verilog test, valid A1 followed by idle DE and ED and then valid B2 produced EDB2 instead of A1B2.

Changed the first-byte register to sample only when valid_in is high and the pair flag is clear. The register then holds the first byte until the second accepted byte completes the pair. The same test passed after the fix, covering byte order, gaps, consecutive valid inputs, output timing, and asynchronous reset with a pending byte.

For similar valid-only width converters, change the input bus during idle cycles to expose incorrect register enables.
