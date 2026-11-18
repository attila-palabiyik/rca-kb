# Check the sample cycle of each operand at a pipeline stage

**Check** which input sample reaches each operand of a clocked stage. Trace both registered paths and paths that bypass a register. At a rising edge, a stage reads the values held by upstream registers before that edge.

- **Operands from the same transaction arrive from different samples.** If the existing registered path establishes the intended latency, register the bypassed operand at the same stage with the same clock and reset. Preserve existing module and port names when the timing repair requires no interface change. Drive different inputs on consecutive cycles so that mixing the samples changes the expected output.
- **The operands already represent the same sample.** Check whether the output appears on the expected edge, then inspect the operation and reset behavior.

**Observed in `TopModule.sv`**, a two-stage unsigned minimum circuit. The second comparator received the registered minimum of `a` and `b` alongside the current `c`. The accepted fix registered `c` with an asynchronous active-low reset and retained the original comparator ports `a` and `b`. The submitted fix made the same timing change and renamed those ports to `data_a` and `data_b`. Its top-level simulation passed, but grading reported a testbench compilation failure. Grading supplied the accepted diff without a compiler diagnostic. A top-level-only test does not exercise named-port connections made directly to a submodule.
