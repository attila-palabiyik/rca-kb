# Debugging guides

## A Moore FSM stalls before its output state

Use this when the transition table appears correct in the HDL but the output state is unreachable or the machine stalls partway through a sequence.

1. Check that each named state has a distinct encoding that fits in the state register. In an ordinary Verilog `case`, the first matching item executes. If two state constants share a value, only the earlier branch can execute for that value.
2. Trace the path to the output state one clock edge at a time. If the branch formulas, output assignments, and reset already match the specification, changing them will leave an encoding collision in place.
3. Verify both input values from each state, including exits from the output state. Check the Moore output before and after each clock edge to confirm it depends on the registered state.

In `TopModule.sv`, `S2` and `S3` both encoded decimal 2, so a transition to `S3` still selected the `S2` branch and the machine could never reach `S4`. Changing only `S3` to decimal 3 passed all 261 grading samples. A local Icarus Verilog simulation also passed all ten transitions, the Moore output checks, and active-low reset.

## A Moore FSM reports a result a clock late

Use this when a state machine reaches the result state on the expected edge but its output is late, or when a change to output timing leaves a rare mismatch around initialization or reset.

1. Trace the edge that samples the final input. A clocked output block reads the old state before nonblocking updates. If the result should appear as soon as the registered state enters the result state, decode that state in a combinational block.
2. Check output reset separately from state reset. When the output must be zero while reset is asserted, retain an explicit reset condition in the combinational decoder. Test reset at startup with the state still unknown and between clock edges while a result is high. A check after the state has settled to idle can pass even when the output depends on that update to clear.

In the `TopModule.sv` FSM for non-overlapping `011100` groups, a state-only combinational decoder passed local checks for all 64 groups, consecutive matches, and asynchronous reset sampled after settling. It differed from the reference in 1 of 1215 grading samples. The reference also decoded the result states combinationally and explicitly forced both outputs low during active-low reset. The grading report did not identify the failing sample.

## A shift-register detector compares bits from different cycles

Use this when a pattern detector combines comparisons and the output is missing or shifted by a clock.

1. Trace the source of each comparison across a rising edge. A clocked block reads the old shift register before nonblocking assignments take effect. A combinational comparison follows the newly shifted value after the edge.
2. Pick a stream with an isolated match and check the output on the edge that samples the final bit and on the following edge. When one comparison is already registered, use its timing and reset behavior as evidence for how to align the other.
3. Check the first few cycles after reset for a window that includes reset contents. An input-valid counter changes that behavior, so add one only when the design calls for it. An exhaustive test of pattern values can still miss a latency error if the scoreboard assumes the same timing as the implementation.

In the `TopModule.sv` detector for `011XXX110`, the prefix followed the updated register while the registered suffix used the old register. The reference fix registered the prefix with the same clock and active-low reset as the suffix. Both comparisons therefore use the pre-edge window, and the match appears one edge after the final bit enters the register. The attempted fix compared the incoming window and added a sample counter. Its local simulation passed against that timing assumption, but 16 of 237 grading samples differed from the reference.
