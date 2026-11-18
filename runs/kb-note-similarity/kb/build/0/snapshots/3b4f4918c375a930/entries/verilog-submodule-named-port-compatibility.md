# Preserve existing submodule ports when fixing Verilog timing

In the unsigned minimum-of-three `TopModule`, the first `slave_mod` registered the minimum of `a` and `b`, while the second compared that result with a combinational copy of `c`. The graded fix changed only the `c1` block to sample `c` on the rising edge and clear it on the falling edge of `rst_n`, using nonblocking assignments. Both operands of the second comparator then came from the same input sample.

My submission made the timing fix and also renamed the existing `slave_mod` input ports from `a` and `b` to `data_a` and `data_b`, following the prose description. I updated both internal instantiations, and a local Icarus testbench that instantiated only `TopModule` passed. The submission failed to compile with the grading testbench. The grading feedback supplied the correct diff with the original port names and did not include the compiler diagnostic.

For a targeted RTL bug fix, preserve the existing submodule interface when the requested behavior can be achieved without changing it. A named-port instantiation of the original submodule can fail to elaborate after a port rename even when all in-file callers were updated. If checking interface compatibility locally, instantiate the submodule with its original named ports as well as testing the top-level behavior.
