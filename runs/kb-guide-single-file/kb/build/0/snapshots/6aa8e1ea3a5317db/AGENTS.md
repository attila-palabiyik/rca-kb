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

## A Gray-code counter repeats or skips a value

Use this when a counter decodes its current Gray value, increments it in binary, and encodes the result back to Gray.

1. Check each decode dependency. The binary MSB equals the Gray MSB. Each lower binary bit is its Gray bit XOR the binary bit immediately above it. For example, Gray `0010` decodes to binary `0011`, so it exposes a low-bit equation that uses the MSB in place of bit 1.
2. Check the width of the increment and confirm the encoder uses `binary ^ (binary >> 1)`. Compare every clock edge with the expected sequence through wraparound. Check that each advance changes one bit, that the output holds between advances, and that asynchronous reset clears the count and restarts the cadence.

In the `TopModule.sv` 4-bit Gray counter, the increment and encoder expressions were correct. The reference changed only the low-bit decoder operand from `bin_out[3]` to `bin_out[1]`. The submission also used combinational conversion and a register that enabled advances every second rising edge. It matched all 421 grading samples, and Icarus Verilog verified the full sequence, wraparound, cadence, and asynchronous reset.

## A shift-register detector misses a match or reports it on the wrong edge

Use this when a pattern detector combines comparisons and the output is missing or shifted by a clock.

1. Read the shift assignment bit by bit. Trace where a new sample enters, where it moves on the next edge, and which old bit drops out. A concatenation can have the correct width while overwriting one bit and leaving the rest unchanged. Once all samples advance through the register in order, map the first and last pattern bits to their slices and check the comparison literals. Include a near match that differs in the suspected bit.
2. Trace the source of each comparison across a rising edge. A clocked block reads the old shift register before nonblocking assignments take effect. A combinational comparison follows the newly shifted value after the edge. If both comparisons already use the required window, preserve their timing when correcting the shift or a literal.
3. Drive an isolated match and check the output on the edge that samples the final bit and on the following edge. Check whether reset contents can participate in the first windows and assert reset between edges while a match is high. An exhaustive test of pattern values can still miss a latency error if the scoreboard assumes the same timing as the implementation.

In the `TopModule.sv` detector for `011XXX110`, the prefix followed the updated register while the registered suffix used the old register. The reference fix registered the prefix with the same clock and active-low reset as the suffix. Both comparisons therefore use the pre-edge window, and the match appears one edge after the final bit enters the register. The attempted fix compared the incoming window and added a sample counter. Its local simulation passed against that timing assumption, but 16 of 237 grading samples differed from the reference.

In a separate `TopModule.sv` task for `011XXX110`, both comparisons already used the same pre-edge window, and the suffix was correct. The prefix slice `[8:6]` compared against `001`. Changing only the literal to `011` matched the reference and passed all 237 grading samples. Icarus Verilog verified all 512 windows, the one-edge latency, and asynchronous reset while `match` was high.

In another `TopModule.sv` task for `011XXX110`, both comparison literals and their registered timing were correct. The update `{a, a_tem[7:0]}` overwrote bit 8 and held bits 7 through 0, so the input stream never reached the suffix comparison. Changing only the update to `{a_tem[7:0], a}` matched all 237 grading samples. Icarus Verilog checked all 512 windows, consecutive windows, the one-edge latency, and asynchronous reset while `match` was high.

## A pipeline stage receives operands from different input cycles

Use this when a downstream stage combines a registered result with another path from the same input sample.

1. Trace both operands to their sampling edges. If one path passes through a register and the other goes directly to the next stage, register the direct path on the same edge and with the same reset as the first path.
2. Drive different inputs on consecutive edges so mixing cycles changes the expected result. Check which edge produces each result and assert asynchronous reset between edges while a result is visible.
3. For a timing-only fix, preserve existing module ports, instance names, and signal names. Review the diff for interface or hierarchy changes. A local bench that instantiates only the top module verifies its own connections and can miss compatibility issues with named submodule ports or hierarchical references.

In the `TopModule.sv` three-input unsigned minimum pipeline, the second comparator saw the previous cycle’s minimum of `a` and `b` together with the current `c`. The reference changed only `c1` to a rising-edge register with active-low asynchronous reset and nonblocking assignments. The submission made that timing change and also renamed submodule ports, instances, and internal signals. Directed and randomized Icarus Verilog checks through the top-level ports passed, but compilation with the grading testbench failed. The grading report provided no compiler diagnostic identifying the cause.

## A synchronous FIFO stalls or misreports full or empty

Use this when a RAM-backed FIFO rejects the first write, loses data, or reports incorrect flags during a request or after wraparound.

1. Start with one write after reset. If the FIFO reports empty and has space, check whether the request reaches both the RAM and the write pointer. Evaluate the enable with the flag both high and low. In a FIFO that blocks writes at full and reads at empty, the enables are `winc && !wfull` and `rinc && !rempty`.
2. If the enables are correct, trace the RAM addresses and compare the pointer blocks. The RAM samples the current address on the rising edge. The pointer should advance on that same edge with a nonblocking assignment under the same enable. A combinational pointer block can feed the address back through the flag that gates the enable.
3. If both pointers advance on the correct edge, check the RAM address and wrap bit separately. On an accepted operation at address `DEPTH-1`, the address should return to zero and the wrap bit should toggle on that same edge. Compare the terminal tests for both fields on both pointers. Correct RAM address sequences can hide a stale wrap bit that corrupts the flags.
4. Assert a request between edges and check that pointers and flags hold until the edge. From reset, fill the FIFO and drain it completely. In a FIFO that uses a wrap bit, both addresses and wrap bits should match after the final read, and `rempty` should assert. Repeat without resetting, checking data order and flags. Test simultaneous requests with space and data available, at full, and at empty.

In the `TopModule.sv` synchronous FIFO, the read pointer was already clocked and the write pointer used `always @(*)`. The reference fix clocked the write pointer with nonblocking assignments and the same asynchronous active-low reset as the read pointer. The RAM and full/empty logic required no edits in the reference. The submitted fix matched all 327 grading samples.

In a separate `TopModule.sv` synchronous FIFO, both pointers were already clocked and the reset flags were correct. `winc & wfull` disabled both the RAM write and the pointer update while the FIFO had room, so the first write could never advance the pointer. The reference corrected the enable to `winc & (!wfull)`. The submission also set a minimum address width of one bit for `DEPTH=1` and matched all 327 grading samples. Local Icarus Verilog checks passed at depths 1, 5, and 16, including simultaneous requests at full and empty.

In another `TopModule.sv` synchronous FIFO, both enables and clocked pointer updates were correct, and the read address returned to zero at `DEPTH-1`. The read wrap bit tested `DEPTH`, which the RAM address never visits. After a full drain from reset, the addresses matched but the stale read wrap bit made the FIFO report full. The reference changed the read wrap test to `DEPTH-1`. The submission also used a minimum one-bit address width for `DEPTH=1` and matched all 327 grading samples. Local Icarus Verilog checks passed at depths 1, 2, 5, and 16.

## A width converter reports a word at the wrong time or with the wrong data

Use this when a width converter advances its count during an idle cycle, asserts output valid at the wrong time, or packs data from the wrong input cycles.

1. Trace the clock edge that loads `data_out`. Compare the input-valid gating and pre-edge counter values with those used by `valid_out`. Check both outputs immediately before and after a completion edge. Even with matching conditions, a combinational `valid_out` can assert before the word loads and clear when the counter advances. If valid must accompany the registered word, register the completion condition on the same edge and check that reset clears both outputs between edges.
2. Count accepted inputs and track leftover bits across word boundaries. For a 24-to-128-bit converter, outputs complete on accepted inputs 6, 11, and 16. A counter that starts at zero has pre-edge values 5, 10, and 15 on those edges. Check the counter and bit slices before changing them.
3. Trace each output slice to the edge that captured its input. For every buffer written through a `valid_in` conditional, check both arms against the intended capture and hold conditions. When the buffer and output register update on the same edge with nonblocking assignments, the output uses the pre-edge buffer value.
4. Exercise every output boundary and any extra count in the valid expression with `valid_in` both high and low. Insert idle cycles with distinct data just before completion. Check the boundary count and output-valid timing, and verify that idle data stays out of the completed word. Compare consecutive output words against the accepted input stream to check bit order and carryover.
5. For a valid-ready input, compare the counter's advance condition with the buffer's capture condition for all four ready/valid pairs. A hold condition must cover either signal being low (`!ready || !valid`). If ready is registered, trace its value before the first rising edge after reset. Check the data load and output-valid conditions separately at the terminal count during a gap, since they can differ in the supplied circuit.

In two `TopModule.sv` 24-to-128-bit converter tasks, the counter and bit slices matched the required packing. One `valid_out` expression used OR between input validity and word completion. Changing OR to AND passed all 261 grading samples. The other already used AND, but checked count 12 where `data_out` loaded at count 10. This omitted the valid pulse on accepted input 11 and asserted it with stale data on accepted input 13. Changing only 12 to 10 passed all 261 grading samples. Icarus Verilog checked both outputs against the accepted bit stream across 13 words, with idle cycles before the completion edges and at count 12, plus asynchronous reset.

In a third `TopModule.sv` 24-to-128-bit converter, the gating and boundary counts already matched the data-load logic, and the bit slices packed the stream correctly. The fix registered `valid_out` on the same rising edge and with the same active-low asynchronous reset as `data_out`, preserving the completion expression. It passed all 261 grading samples. Icarus Verilog verified 19 words against a bit-stream scoreboard, including gaps at completion boundaries and reset between edges while valid was high.

In the `TopModule.sv` 8-to-16-bit converter, the pair flag toggled on valid inputs, and `data_out` and `valid_out` already used the same completion condition. The byte buffer held on valid cycles and captured during gaps, so the high output byte could come from an idle cycle. Swapping the buffer's ternary arms to `valid_in ? data_in : data_r` matched the reference fix and passed all 141 grading samples. Icarus Verilog verified byte order with input gaps and consecutive pairs, along with asynchronous reset.

In the `TopModule.sv` 1-to-6-bit serial-to-parallel converter, the shift register captured only when both `ready_a` and `valid_a` were high, but the counter held only when both were low. The reference changed just `~ready_a && ~valid_a` to `~ready_a || ~valid_a`. In that circuit, `ready_a` rises on the first clock after reset. At count 5, a cycle with `valid_a` low holds `data_b` while `valid_b` still asserts. The submission tied `ready_a` high and gated `valid_b` with `valid_a`. It passed local Icarus Verilog checks for all 64 words, input gaps, consecutive words, and reset using those assumptions, but differed from the reference in 16 of 151 samples. The grading report supplied only the mismatch count.

## A pipelined multiplier drops or duplicates a partial product

Use this when a shift-and-add multiplier gives wrong products for particular multiplier bits.

1. Follow each multiplier bit through its shifted partial product and every registered sum to the output. Each partial product should contribute once. Check both operands of every addition, even when the adjacent stage looks correct.
2. To isolate a term in simulation, use a nonzero multiplicand and set one multiplier bit at a time. Expect the multiplicand shifted by that bit index. Then send different operand pairs on consecutive cycles and compare against the products in input order at the expected latency. Assert reset between edges with a result visible and another product pending to verify that both clear.

In the 4-bit unsigned pipelined multiplier in `TopModule.sv`, partial-product generation was correct, but `adder_1` added `temp[2]` twice and omitted `temp[3]`. Replacing the second operand with `temp[3]` matched all 43 grading samples. Icarus Verilog also passed all 256 operand pairs on consecutive cycles and verified two-stage timing and asynchronous reset.

## An adder loses or creates a carry

Use this when a combinational adder returns the wrong sum or carry-out.

1. Check the generate and propagate expressions before tracing the carry network. Force a carry with both operand bits high and carry-in low. Check propagation with exactly one operand bit high and toggle carry-in. With both operand bits low, carry-out should stay low for either carry-in.
2. If those checks pass, trace the carry feeding each sum bit and the final carry-out. For a small adder, exhaustively compare the concatenated carry-out and sum against a widened addition with both carry-in values.

In the 4-bit `TopModule.sv` adder, the propagate expression, carry recurrence, and sum equations matched the specification. The generate expression duplicated the propagate XOR. The reference changed only `G` to `A_in & B_in`. The submission also implemented the equations using gate primitives and expanded the carries into look-ahead terms. It matched all 425 grading samples, and Icarus Verilog verified all 512 binary input combinations.

## A fractional divider has the right frequency but the wrong pulse width

Use this when a divider alternates between integer periods and its output samples disagree even though the average frequency is correct.

1. Derive the period schedule from the stated ratio and check each mode boundary. For 8.7× division, three 8-cycle periods and seven 9-cycle periods give 10 output periods in 87 input cycles. If the period counters and mode switch already produce that schedule, trace the output decoder.
2. For each mode, list the pre-edge counter values that drive the registered output high. With a counter starting at zero, an inclusive comparison against 3 gives four high cycles. Check falling edges within both modes and rising edges across the mode switches. An average-frequency check can pass with either threshold.
3. When the description gives only a frequency ratio, keep pulse width as a separate question. If the two output expressions differ, calculate the waveform for either candidate edit. A scoreboard that assumes one candidate's pulse width can confirm its implementation while leaving the choice between candidates unresolved.

In the `TopModule.sv` 8.7× fractional divider, the reference changed the even-period threshold from `(div_e >> 1) + 1` to `(div_e >> 2) + 1`, matching the existing odd-period formula. This gives four high cycles in both modes. The submission changed the odd-period formula to match the even branch, yielding six high cycles in both modes. Its Icarus Verilog checks passed for the period schedule, asynchronous reset, and its assumed six-cycle width. The grading report found 460 mismatches in 2021 samples.
