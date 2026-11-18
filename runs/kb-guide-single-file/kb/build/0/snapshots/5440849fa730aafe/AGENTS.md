# Debugging guides

## A Moore FSM takes the wrong transition

Use this when a Moore FSM stalls, never reaches its output state, or takes the wrong path after reaching it.

1. Compare every state and input pair against the transition table. For `data ? A : B`, read the `1` column as `A` and the `0` column as `B`. Check both destinations even when the expression repeats the same state.
2. If the branch expressions match the table, check that each named state has a distinct encoding that fits in the state register. In an ordinary Verilog `case`, the first matching item executes. If two constants share a value, only the earlier branch executes for that value.
3. Reach the output state through the normal input sequence, then apply each possible exit input in a separate run. Check the destination state as well as the flag because two different destinations can both clear the flag. Check the Moore output before and after each clock edge.

In one `TopModule.sv` task, the expressions matched the table, but `S2` and `S3` both encoded decimal 2. A transition to `S3` still selected the `S2` branch, so the FSM never reached `S4`. Changing only `S3` to decimal 3 passed all 261 grading samples.

In a separate `TopModule.sv` task, the encodings were distinct and the FSM reached `S4`, but its exit expression was `data ? S1 : S1`. For `data = 0`, the table required `S0`. Changing only the false arm to `S0` passed all 261 grading samples. Icarus Verilog verified all ten transitions, the Moore output, and active-low reset.

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

## A synchronous FIFO pointer changes between clock edges

Use this when a RAM-backed FIFO loses data, skips addresses, or changes its full or empty flag as soon as a request is asserted.

1. Trace each RAM port's enable and address back to its pointer. The RAM samples the current address on the rising edge. The pointer should advance on that same edge with a nonblocking assignment, and only when the port's enable is high.
2. Compare the read and write pointer blocks. A combinational block that assigns the next pointer or assigns the pointer to itself feeds the current address back into its own logic. Check whether that address also affects the flag that gates the enable.
3. Assert a request between clock edges and check that the pointer and flags hold until the edge. Then fill and drain through wraparound, checking data order and flags. Test simultaneous requests with space and data available, at full, and at empty.

In the `TopModule.sv` synchronous FIFO, the read pointer was already clocked and the write pointer used `always @(*)`. The reference fix clocked the write pointer with nonblocking assignments and the same asynchronous active-low reset as the read pointer. The RAM and full/empty logic required no edits in the reference. The submitted fix matched all 327 grading samples.

## A width converter asserts valid without completing a word

Use this when a valid-only width converter asserts output valid early or reports the same word during an input gap.

1. Trace the clock edge that loads `data_out`. Write down every condition required for that load, then compare it with the condition that asserts `valid_out`. If both an accepted input and a word boundary are required, test each condition on its own as well as both together.
2. Count accepted inputs and track leftover bits across word boundaries. For a 24-to-128-bit converter, outputs complete on accepted inputs 6, 11, and 16. A counter that starts at zero has pre-edge values 5, 10, and 15 on those edges. Check the counter and bit slices before changing them.
3. Insert idle cycles just before each completion edge so the boundary count holds with `valid_in` low. Check that `valid_out` stays low until the next accepted input. Compare the output against a stream of accepted input bits in transmission order to check bit order and carryover.

In the `TopModule.sv` 24-to-128-bit converter, the counter and bit slices matched the required packing. The data register updated only when an input was valid at a completion count, but `valid_out` used OR between those conditions. Changing OR to AND passed all 261 grading samples.

## A pipelined multiplier drops or duplicates a partial product

Use this when a shift-and-add multiplier gives wrong products for particular multiplier bits.

1. Follow each multiplier bit through its shifted partial product and every registered sum to the output. Each partial product should contribute once. Check both operands of every addition, even when the adjacent stage looks correct.
2. To isolate a term in simulation, use a nonzero multiplicand and set one multiplier bit at a time. Expect the multiplicand shifted by that bit index. Then send different operand pairs on consecutive cycles and compare against the products in input order at the expected latency. Assert reset between edges with a result visible and another product pending to verify that both clear.

In the 4-bit unsigned pipelined multiplier in `TopModule.sv`, partial-product generation was correct, but `adder_1` added `temp[2]` twice and omitted `temp[3]`. Replacing the second operand with `temp[3]` matched all 43 grading samples. Icarus Verilog also passed all 256 operand pairs on consecutive cycles and verified two-stage timing and asynchronous reset.
