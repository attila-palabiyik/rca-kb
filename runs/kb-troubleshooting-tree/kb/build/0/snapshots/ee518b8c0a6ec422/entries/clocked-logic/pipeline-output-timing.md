# Check the edge that publishes a pipelined result

**Check** the result just after the edge that captures a new input sample and just after the following edge. Drive successive samples with different expected results so an early or late output is visible. A combinational output follows the newly updated stage registers after the edge. A clocked output with a nonblocking assignment uses the values those registers held before the edge.

- **The result appears one edge early and the design calls for a registered final stage.** Register the final expression using the specified clock and reset. Check that consecutive results still arrive one per cycle and that an asynchronous reset clears the output and any in-flight results.
- **The result appears one edge late and the design calls for a combinational final stage.** Check for an extra output register.
- **The result appears on the intended edge.** Inspect the arithmetic and reset behavior if the output still fails.

**Observed in `TopModule.sv`**, an unsigned 4-bit pipelined multiplier with a combinational final sum after the registered partial sums. The reference fix registered the final sum on `posedge clk` and cleared it on `negedge rst_n`. The product appeared on the rising edge after its partial sums were captured. The submitted fix made the same change and matched all 43 graded samples.
