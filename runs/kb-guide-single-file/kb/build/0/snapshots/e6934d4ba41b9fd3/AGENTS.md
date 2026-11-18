# Debugging guides

## A Moore FSM takes the wrong transition

Use this when a Moore FSM stalls, never reaches its output state, or takes the wrong path after reaching it.

1. Compare every state and input pair against the transition table. For `data ? A : B`, read the `1` column as `A` and the `0` column as `B`. Check both destinations even when the expression repeats the same state.
2. If the branch expressions match the table, check that each named state has a distinct encoding that fits in the state register. In an ordinary Verilog `case`, the first matching item executes. If two constants share a value, only the earlier branch executes for that value.
3. Reach each result state through the normal input sequence, then apply each possible exit input in a separate run. Check the destination state as well as the flag because two different destinations can both clear the flag. Check the Moore output before and after each clock edge.
4. For fixed-size groups, check whether the edge leaving each result state also samples the first bit of the next group. If it does, compare those transitions with the initial state's transitions. Run adjacent groups without resetting between them.

In one `TopModule.sv` task, the expressions matched the table, but `S2` and `S3` both encoded decimal 2. A transition to `S3` still selected the `S2` branch, so the FSM never reached `S4`. Changing only `S3` to decimal 3 passed all 261 grading samples.

In a separate `TopModule.sv` task, the encodings were distinct and the FSM reached `S4`, but its exit expression was `data ? S1 : S1`. For `data = 0`, the table required `S0`. Changing only the false arm to `S0` passed all 261 grading samples. Icarus Verilog verified all ten transitions, the Moore output, and active-low reset.

In the `TopModule.sv` detector for non-overlapping `011100` groups, both result states were reachable, but the failure state `sf6` unconditionally advanced to `s1`. After a failed group, this treated a leading `1` as a matched first bit, producing a false match if the next group was `111100`. The reference changed only the `sf6` exit to `data ? sf1 : s1`, matching the success state's exit. The submission shared that transition across `idle`, `s6`, and `sf6`, used wildcard sensitivity for both combinational blocks, and retained explicit output reset gating. It passed all 1215 grading samples and all 4096 adjacent group pairs in Icarus Verilog.

## A Moore FSM reports a result a clock late

Use this when a state machine reaches the result state on the expected edge but its output is late, or when a change to output timing leaves a rare mismatch around initialization or reset.

1. Trace the edge that samples the final input. A clocked output block reads the old state before nonblocking updates. If the result should appear as soon as the registered state enters the result state, decode that state in a combinational block.
2. Check output reset separately from state reset. When the output must be zero while reset is asserted, retain an explicit reset condition in the combinational decoder. Test reset at startup with the state still unknown and between clock edges while a result is high. A check after the state has settled to idle can pass even when the output depends on that update to clear.

In the `TopModule.sv` FSM for non-overlapping `011100` groups, a state-only combinational decoder passed local checks for all 64 groups, consecutive matches, and asynchronous reset sampled after settling. It differed from the reference in 1 of 1215 grading samples. The reference also decoded the result states combinationally and explicitly forced both outputs low during active-low reset. The grading report did not identify the failing sample.

## An up/down counter moves in the wrong direction

Use this when the count moves opposite to the selected direction or leaves its valid range.

1. For each direction, check an ordinary step and a wraparound step. A correct wraparound assignment can hide the wrong arithmetic operator in the ordinary branch. For a decimal counter, check `4 → 5` and `9 → 0` in up mode, and `4 → 3` and `0 → 9` in down mode.
2. Change direction at an interior count and check the next rising edge. If the counter has a registered status flag, check its value against the pre-edge count separately.

In the `TopModule.sv` decimal up/down counter, both wraparound branches and the registered `zero` flag were correct. The ordinary step subtracted one in both modes. Changing only the up-mode operator from subtraction to addition matched the reference fix and passed all 289 grading samples.

## A counter status flag asserts one cycle early

Use this when a status flag should report the previous count, but it follows the current count.

1. Check the flag on both the edge that reaches the target count and the following edge. A combinational comparison follows the updated count. A clocked comparison with a nonblocking assignment reads the pre-edge count.
2. Check both count directions and assert asynchronous reset between edges while the flag is high. If reset must clear the flag even though the reset count satisfies the comparison, check that releasing reset leaves the flag low until the next rising edge.

In the `TopModule.sv` decimal up/down counter, the count and wraparound logic already worked. The combinational `zero` flag asserted as soon as the count reached zero and also asserted when reset was released between edges. Registering the comparison with the same rising edge and active-low asynchronous reset as the count made `zero` report the previous count. The fix passed all 289 grading samples.

## A shift-register detector misses a match or reports it on the wrong edge

Use this when a pattern detector combines comparisons and the output is missing or shifted by a clock.

1. Map the pattern's first and last bits to register positions using the shift direction. Check each slice and binary literal against the pattern. Include a near match that differs in the suspected bit.
2. Trace the source of each comparison across a rising edge. A clocked block reads the old shift register before nonblocking assignments take effect. A combinational comparison follows the newly shifted value after the edge. If two comparisons already use the same registered window and that latency is required, preserve their timing when correcting a literal.
3. Drive an isolated match and check the output on the edge that samples the final bit and on the following edge. Check whether reset contents can participate in the first windows and assert reset between edges while a match is high. An exhaustive test of pattern values can still miss a latency error if the scoreboard assumes the same timing as the implementation.

In the `TopModule.sv` detector for `011XXX110`, the prefix followed the updated register while the registered suffix used the old register. The reference fix registered the prefix with the same clock and active-low reset as the suffix. Both comparisons therefore use the pre-edge window, and the match appears one edge after the final bit enters the register. The attempted fix compared the incoming window and added a sample counter. Its local simulation passed against that timing assumption, but 16 of 237 grading samples differed from the reference.

In a separate `TopModule.sv` task for `011XXX110`, both comparisons already used the same pre-edge window, and the suffix was correct. The prefix slice `[8:6]` compared against `001`. Changing only the literal to `011` matched the reference and passed all 237 grading samples. Icarus Verilog verified all 512 windows, the one-edge latency, and asynchronous reset while `match` was high.

## A pipeline stage receives operands from different input cycles

Use this when a downstream stage combines a registered result with another path from the same input sample.

1. Trace both operands to their sampling edges. If one path passes through a register and the other goes directly to the next stage, register the direct path on the same edge and with the same reset as the first path.
2. Drive different inputs on consecutive edges so mixing cycles changes the expected result. Check which edge produces each result and assert asynchronous reset between edges while a result is visible.
3. For a timing-only fix, preserve existing module ports, instance names, and signal names. Review the diff for interface or hierarchy changes. A local bench that instantiates only the top module verifies its own connections and can miss compatibility issues with named submodule ports or hierarchical references.

In the `TopModule.sv` three-input unsigned minimum pipeline, the second comparator saw the previous cycle’s minimum of `a` and `b` together with the current `c`. The reference changed only `c1` to a rising-edge register with active-low asynchronous reset and nonblocking assignments. The submission made that timing change and also renamed submodule ports, instances, and internal signals. Directed and randomized Icarus Verilog checks through the top-level ports passed, but compilation with the grading testbench failed. The grading report provided no compiler diagnostic identifying the cause.

## A synchronous FIFO pointer changes between clock edges

Use this when a RAM-backed FIFO loses data, skips addresses, or changes its full or empty flag as soon as a request is asserted.

1. Trace each RAM port's enable and address back to its pointer. The RAM samples the current address on the rising edge. The pointer should advance on that same edge with a nonblocking assignment, and only when the port's enable is high.
2. Compare the read and write pointer blocks. A combinational block that assigns the next pointer or assigns the pointer to itself feeds the current address back into its own logic. Check whether that address also affects the flag that gates the enable.
3. Assert a request between clock edges and check that the pointer and flags hold until the edge. Then fill and drain through wraparound, checking data order and flags. Test simultaneous requests with space and data available, at full, and at empty.

In the `TopModule.sv` synchronous FIFO, the read pointer was already clocked and the write pointer used `always @(*)`. The reference fix clocked the write pointer with nonblocking assignments and the same asynchronous active-low reset as the read pointer. The RAM and full/empty logic required no edits in the reference. The submitted fix matched all 327 grading samples.

## A width converter reports a word at the wrong time or with the wrong data

Use this when a valid-only width converter asserts output valid at the wrong time or packs bytes from the wrong input cycles.

1. Trace the clock edge that loads `data_out`. Compare both the input-valid gating and each pre-edge counter value with the conditions that assert `valid_out`. Exercise every output boundary and any extra count in the valid expression, with `valid_in` both high and low.
2. Count accepted inputs and track leftover bits across word boundaries. For a 24-to-128-bit converter, outputs complete on accepted inputs 6, 11, and 16. A counter that starts at zero has pre-edge values 5, 10, and 15 on those edges. Check the counter and bit slices before changing them.
3. Trace each output slice to the edge that captured its input. For every buffer written through a `valid_in` conditional, check both arms against the intended capture and hold conditions. When the buffer and output register update on the same edge with nonblocking assignments, the output uses the pre-edge buffer value.
4. Insert idle cycles with distinct data just before a completion edge. Check that the boundary count holds, `valid_out` stays low, and idle data stays out of the completed word. Compare consecutive output words against the accepted input stream to check bit order and carryover.

In two `TopModule.sv` 24-to-128-bit converter tasks, the counter and bit slices matched the required packing. One `valid_out` expression used OR between input validity and word completion. Changing OR to AND passed all 261 grading samples. The other already used AND, but checked count 12 where `data_out` loaded at count 10. This omitted the valid pulse on accepted input 11 and asserted it with stale data on accepted input 13. Changing only 12 to 10 passed all 261 grading samples. Icarus Verilog checked both outputs against the accepted bit stream across 13 words, with idle cycles before the completion edges and at count 12, plus asynchronous reset.

In the `TopModule.sv` 8-to-16-bit converter, the pair flag toggled on valid inputs, and `data_out` and `valid_out` already used the same completion condition. The byte buffer held on valid cycles and captured during gaps, so the high output byte could come from an idle cycle. Swapping the buffer's ternary arms to `valid_in ? data_in : data_r` matched the reference fix and passed all 141 grading samples. Icarus Verilog verified byte order with input gaps and consecutive pairs, along with asynchronous reset.

## A pipelined multiplier drops or duplicates a partial product

Use this when a shift-and-add multiplier gives wrong products for particular multiplier bits.

1. Follow each multiplier bit through its shifted partial product and every registered sum to the output. Each partial product should contribute once. Check both operands of every addition, even when the adjacent stage looks correct.
2. To isolate a term in simulation, use a nonzero multiplicand and set one multiplier bit at a time. Expect the multiplicand shifted by that bit index. Then send different operand pairs on consecutive cycles and compare against the products in input order at the expected latency. Assert reset between edges with a result visible and another product pending to verify that both clear.

In the 4-bit unsigned pipelined multiplier in `TopModule.sv`, partial-product generation was correct, but `adder_1` added `temp[2]` twice and omitted `temp[3]`. Replacing the second operand with `temp[3]` matched all 43 grading samples. Icarus Verilog also passed all 256 operand pairs on consecutive cycles and verified two-stage timing and asynchronous reset.
