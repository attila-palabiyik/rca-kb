---
name: debug-verilog-cycle-alignment
description: Diagnose Verilog or SystemVerilog output timing bugs at clock and reset boundaries, including transitions between registered and combinational output logic.
---

# Debug Verilog cycle alignment

1. Trace each input to the output through its registers. For a clocked block using nonblocking assignments, the right-hand side reads values from before the edge. After those assignments take effect, a combinational check sees the updated values. When two checks describe parts of the same window or transaction, label the cycle each one observes.
2. Use the existing registered paths and the timing specification to identify the intended sample. If a check bypasses a register stage shared by related checks, first evaluate a local fix that puts all checks on the same stage. Check whether evaluating the incoming data or adding a startup counter would change the output edge or post-reset behavior.
3. Simulate an isolated match and check the output after nonblocking updates on the completion edge and the following edge. Exercise reset and startup too. Derive the expected cycle and reset behavior independently of the candidate patch so the test can distinguish a wrong output edge from a wrong result.
4. When replacing a clocked output block with combinational decoding of registered state, carry over any explicit reset override required by the outputs. A state register with asynchronous reset still updates through a nonblocking assignment. At reset assertion the decoder can see the old state until that update, and at startup the state can be unknown. If the outputs must be inactive whenever reset is low, include reset directly in the combinational block. Test reset held low at startup and reset asserted between clock edges while an output is high. A check after a delay observes only settled values.

## Observed result

In the `011XXX110` shift-register detector task in `TopModule.sv`, the combinational prefix comparison saw the newly shifted window while the registered suffix comparison used the pre-edge window. The submitted fix registered comparisons of the window including the incoming bit and added a nine-sample startup guard. Its self-written Icarus test passed all 512 windows and 4,096 streaming samples under those assumptions. The grader reported 16 mismatches in 237 samples.

The supplied correct fix registered the prefix comparison on the same clock edge as the suffix comparison and used the same asynchronous active-low reset. Both comparisons therefore use the pre-edge shift-register contents. A matching window is reported one rising edge after its last bit enters the register. The reference also preserves the original zero-filled reset window and adds no startup counter.

In the non-overlapping `011100` detector task in `TopModule.sv`, the submitted fix replaced clocked outputs with combinational decoding of the sixth-bit success and failure states. It relied on the state register's reset to clear the outputs. Its Icarus test passed all 64 six-bit groups and checked reset after a delay. The grader reported one mismatch in 1,215 samples. The supplied correct fix also decodes the sixth-bit states combinationally and explicitly forces both outputs low when `rst_n` is low. The grading feedback did not identify the mismatching sample.
