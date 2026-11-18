# Capturing the first byte in an 8-to-16-bit width converter

TopModule tracks whether a first byte is pending and concatenates that byte with the second valid input. The first-byte register had its enable reversed. It held on valid cycles and captured invalid input on idle cycles. A directed Icarus Verilog test reproduced the bug by sending A1, two invalid cycles ending in ED, and B2. The output was EDB2 instead of A1B2.

Enable the byte register with valid_in && !flag so it captures the first accepted byte and holds through any gap. The existing flag toggling and registered data and valid updates already implement the correct pair timing. The same test passed after the edit, including contiguous inputs, idle cycles, and asynchronous reset with a byte pending.

For similar valid-only packers, vary the input bus during gaps and check that only accepted input values appear in the output word.
