# Debugging guides

## An FSM takes the wrong transition

Use this when an FSM stalls, skips a state, or takes the wrong path after reaching a state.

1. Compare every state and input pair against the transition table. For `data ? A : B`, read the `1` column as `A` and the `0` column as `B`. Check both destinations even when the expression repeats the same state. For an overlapping detector, derive each fallback by appending the new bit and finding the longest suffix that is also a prefix of the pattern. Exercise fallbacks from partial matches as well as exits from a completed match.
2. If the branch expressions match the table, compare the effective bit patterns of all state constants. Check for truncation at the literal's declared width and at assignment to the state register. For example, `4'd20` already has the value 4 before assignment. Compile with warnings enabled to help spot truncated literals. In an ordinary Verilog `case`, the first matching item executes, so a duplicate encoding selects the earlier branch.
3. Reach each result state through the normal input sequence, then apply each possible exit input in a separate run. Check the destination state as well as the flag because two different destinations can both clear the flag. Check the Moore output before and after each clock edge.
4. For fixed-size groups, check whether the edge leaving each result state also samples the first bit of the next group. If it does, compare those transitions with the initial state's transitions. Run adjacent groups without resetting between them.
5. For a timed FSM, trace the pre-edge timer, state, output buffers, visible outputs, and reload condition through startup and a phase boundary. Check the transition destinations and threshold independently. If the timer compares a buffered output with the visible output, check whether the two values come from different clock edges.
6. A reload of the form `!visible && buffered` needs a cycle with the buffer high and the visible output low. A combinational connection from the buffer to the output removes that cycle. A registered output samples the pre-edge buffer, allowing the timer to reload on the same edge that makes the output visible. A condition of `visible && buffered` can reload throughout the steady phase. Trace with requests inactive first, then check whether a higher-priority request can override a reload. Compare the startup and boundary waveforms with the source timing comments before changing the threshold or reset values.

In one `TopModule.sv` task, the expressions matched the table, but `S2` and `S3` both encoded decimal 2. A transition to `S3` still selected the `S2` branch, so the FSM never reached `S4`. Changing only `S3` to decimal 3 passed all 261 grading samples.

The same encoding collision occurred in the `TopModule.sv` overlapping `1011` detector. Both overlap paths were already correct. Changing only `S3` from 2 to 3 passed all 153 grading samples. Icarus Verilog checked every 12-bit stream, including the next-cycle flag timing, and verified asynchronous reset while the flag was high.

In the `TopModule.sv` detector for non-overlapping `011100` groups with a truncated state encoding, both result-state exits already handled the first bit of the next group correctly. The failure state `sf6` used `4'd20`, which truncated to 4 and selected the earlier `s4` branch. The reference changed only `sf6` to `4'd12`. The submission also used wildcard sensitivity and simplified the explicit output reset condition. It matched all 1215 grading samples, and Icarus Verilog verified all 4096 adjacent group pairs, output timing, and asynchronous reset.

In a separate `TopModule.sv` task, the encodings were distinct and the FSM reached `S4`, but its exit expression was `data ? S1 : S1`. For `data = 0`, the table required `S0`. Changing only the false arm to `S0` passed all 261 grading samples. Icarus Verilog verified all ten transitions, the Moore output, and active-low reset.

In the `TopModule.sv` overlapping `1011` detector, `10110111` exercises overlap after a completed match, and `101011` exercises fallback after a partial match. After `101` followed by `0`, the suffix `10` is still a valid prefix, so the `S3` zero-input branch must go to `S2`. This single change passed all 153 grading samples. Icarus Verilog checked all 4096 12-bit streams with the existing next-cycle flag timing and verified asynchronous reset.

In the `TopModule.sv` detector for non-overlapping `011100` groups, both result states were reachable, but the failure state `sf6` unconditionally advanced to `s1`. After a failed group, this treated a leading `1` as a matched first bit, producing a false match if the next group was `111100`. The reference changed only the `sf6` exit to `data ? sf1 : s1`, matching the success state's exit. The submission shared that transition across `idle`, `s6`, and `sf6`, used wildcard sensitivity for both combinational blocks, and retained explicit output reset gating. It passed all 1215 grading samples and all 4096 adjacent group pairs in Icarus Verilog.

Three `TopModule.sv` traffic light tasks used the same state, buffer, visible output, and timer stages. One reference fixed the red and green destinations to green and yellow, respectively. A second fixed `green && p_green` to `!green && p_green` because the original condition kept reloading 60 during steady green. A third already had the correct destinations and reload expressions, but its combinational output block made each visible light follow its buffer and suppressed the reload pulse. The reference changed only that output block to a rising-edge register with active-low asynchronous reset and nonblocking assignments.

The third reference keeps the `cnt == 3` transition threshold. At an ordinary boundary, the state advances as the count falls to 2, the buffer changes as the count falls to 1, and the next edge both reloads the timer and shows the new light. The source comment identified the separate buffer and visible stages, but predicted a count of 0 at the visible change. The reference resets to idle with all lights off and a count of 10. After release, the timer shows 9 and then 8 while the lights are off, then reloads 10 as red lights. In all three tasks, submissions that rewrote the timing and lit red during reset passed local checks built around the prose and differed from the reference in 220 of 517 grading samples.

## A Moore FSM reports a result a clock late

Use this when a state machine reaches the result state on the expected edge but its output is late, or when a change to output timing leaves a rare mismatch around initialization or reset.

1. Trace the edge that samples the final input. A clocked output block reads the old state before nonblocking updates. If the result should appear as soon as the registered state enters the result state, decode that state in a combinational block.
2. Check output reset separately from state reset. When the output must be zero while reset is asserted, retain an explicit reset condition in the combinational decoder. Test reset at startup with the state still unknown and between clock edges while a result is high. A check after the state has settled to idle can pass even when the output depends on that update to clear.

In the `TopModule.sv` FSM for non-overlapping `011100` groups, a state-only combinational decoder passed local checks for all 64 groups, consecutive matches, and asynchronous reset sampled after settling. It differed from the reference in 1 of 1215 grading samples. The reference also decoded the result states combinationally and explicitly forced both outputs low during active-low reset. The grading report did not identify the failing sample.

## An up/down counter moves in the wrong direction or wraps late

Use this when the count moves opposite to the selected direction or leaves its valid range.

1. For each direction, check an ordinary step and a wraparound step. For a decimal counter, check `4 → 5` and `9 → 0` in up mode, and `4 → 3` and `0 → 9` in down mode. If ordinary steps pass but the count leaves its range, compare the wrap condition against the last valid pre-edge count. An up-mode test for `10` lets `9` increment to `10` for one cycle before wrapping.
2. Change direction at an interior count and check the next rising edge. If the counter has a registered status flag, check its value against the pre-edge count separately.

In the `TopModule.sv` decimal up/down counter, both wraparound branches and the registered `zero` flag were correct. The ordinary step subtracted one in both modes. Changing only the up-mode operator from subtraction to addition matched the reference fix and passed all 289 grading samples.

In a separate `TopModule.sv` decimal up/down counter, ordinary steps, down-mode wraparound, and the registered `zero` flag were correct. Changing only the up-mode wrap condition from `number == 10` to `number == 4'd9` passed all 289 grading samples. Icarus Verilog verified both wraps, direction changes, the one-cycle `zero` delay, and asynchronous reset.

## A counter output or status flag is one cycle out of step

Use this when an exposed count and its flag disagree, or when a flag should report an earlier count.

1. Trace the internal count, the exposed count, and the flag across the same edge. A combinational output follows the updated count. A clocked assignment with nonblocking assignments samples the pre-edge count. If the flag already samples that value and both outputs are meant to be registered, check whether the exposed count needs to sample it on the same edge.
2. Use distinct consecutive inputs and check wraparound and any set-to-zero operation. If both outputs agree under two candidate fixes, check the edge on which a set value first appears and the first edge after reset release. Check explicit reset assignments separately from the normal count comparison, including an assertion between edges.

In the `TopModule.sv` decimal up/down counter, the combinational `zero` flag followed the updated count and asserted on reset release between edges. Registering the comparison with the count's rising edge and active-low asynchronous reset made the flag report the pre-edge count. The fix passed all 289 grading samples.

In the `TopModule.sv` hexadecimal settable counter, the flag already sampled the pre-edge `num`, while the exposed `number` followed the updated `num` combinationally. The reference registered only `number`, so both outputs sample the same pre-edge count. A set value first appears at the output one rising edge after capture. Reset clears both outputs, and the first rising edge after release reports `number = 0` and `zero = 1`. The submission computed both outputs from the next count and asserted `zero` during reset. Its Icarus Verilog checks passed with those expectations, but 248 of 273 grading samples differed from the reference.

## A Gray-code counter repeats or skips a value

Use this when a counter decodes its current Gray value, increments it in binary, and encodes the result back to Gray.

1. Check each decode dependency. The binary MSB equals the Gray MSB. Each lower binary bit is its Gray bit XOR the binary bit immediately above it. For example, Gray `0010` decodes to binary `0011`, so it exposes a low-bit equation that uses the MSB in place of bit 1.
2. Check the width of the increment and confirm the encoder uses `binary ^ (binary >> 1)`. Check the first two advances: binary `0010` should encode as Gray `0011`, but a shift by two produces `0010` and changes two bits from the previous Gray value `0001`.
3. If the conversion and increment are correct, trace the decode register, increment register, and visible Gray output across the first few edges after reset. A combinational output exposes the newly encoded value as soon as the increment register changes. A registered output samples the pre-edge encoded value. Check which rising edge should first show `0001`.
4. Compare every clock edge with the expected sequence through wraparound. Check that each advance changes one bit, that the output holds between advances, and that asynchronous reset clears the count and restarts the cadence.

In the `TopModule.sv` 4-bit Gray counter, the increment and encoder expressions were correct. The reference changed only the low-bit decoder operand from `bin_out[3]` to `bin_out[1]`. The submission also used combinational conversion and a register that enabled advances every second rising edge. It matched all 421 grading samples, and Icarus Verilog verified the full sequence, wraparound, cadence, and asynchronous reset.

In a separate `TopModule.sv` 4-bit Gray counter, the decoder dependencies and binary increment were correct. The reference fixed only the encoder shift from `>> 2` to `>> 1`, retaining the original clocked stages. The submission used the corrected encoder with combinational conversion and an explicit every-other-edge enable, and matched all 421 grading samples. Icarus Verilog verified the full sequence, one-bit transitions through wraparound, and cadence after asynchronous reset.

In a third `TopModule.sv` 4-bit Gray counter, the decoder, increment, and encoder expressions were correct. The output followed `gray_wire` combinationally and exposed `0001` on the first rising edge after reset release. The reference kept the existing conversion and increment stages and registered `gray_out` with nonblocking assignments and active-low asynchronous reset. The first edge still computes the increment, and the second edge makes it visible. The submission used combinational conversion and an every-other-edge enable that first advances on the second rising edge. It matched all 421 grading samples, and Icarus Verilog verified wraparound, one-bit transitions, and cadence after a between-edge reset.

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

1. Trace the clock edge that loads `data_out`. Compare the input-valid gating and pre-edge counter values with those used by `valid_out`. Check both outputs immediately before and after a completion edge. Even with matching conditions, a combinational `valid_out` can assert before the word loads and clear when the counter advances. For a timing-only fix, register the existing valid expression on the same edge and check that reset clears both outputs between edges. Test changes to the valid predicate or ready timing separately.
2. Count accepted inputs and track leftover bits across word boundaries. Check whether the wrap condition lets the counter reach every pre-edge value used to load a word. For a 6-bit serial word, the counter starts at zero, reaches 5 after the fifth accepted bit, and wraps on the sixth. For a 24-to-128-bit converter, outputs complete on accepted inputs 6, 11, and 16, at pre-edge counts 5, 10, and 15. Check the bit slices against those boundaries.
3. Trace each output slice to the edge that captured its input. Check both arms of each `valid_in` conditional against the intended capture and hold conditions. Even with correct gating, a combinational buffer can follow the next input before the output edge and overwrite the earlier sample. When the buffer and output register update on the same edge with nonblocking assignments, the output uses the pre-edge buffer value.
4. Exercise every output boundary and any extra count in the valid expression with `valid_in` both high and low. Insert idle cycles with distinct data just before completion. Check the boundary count and output-valid timing, and verify that idle data stays out of the completed word. Compare consecutive output words against the accepted input stream to check bit order and carryover.
5. For a valid-ready input, compare the counter's advance condition with the buffer's capture condition for all four ready/valid pairs. A hold condition must cover either signal being low (`!ready || !valid`). If ready is registered, trace its value before the first rising edge after reset. Check the data load and output-valid conditions separately at the terminal count during a gap, since they can differ in the supplied circuit.

In two `TopModule.sv` 24-to-128-bit converter tasks, the counter and bit slices matched the required packing. One `valid_out` expression used OR between input validity and word completion. Changing OR to AND passed all 261 grading samples. The other already used AND, but checked count 12 where `data_out` loaded at count 10. This omitted the valid pulse on accepted input 11 and asserted it with stale data on accepted input 13. Changing only 12 to 10 passed all 261 grading samples. Icarus Verilog checked both outputs against the accepted bit stream across 13 words, with idle cycles before the completion edges and at count 12, plus asynchronous reset.

In a third `TopModule.sv` 24-to-128-bit converter, the gating and boundary counts already matched the data-load logic, and the bit slices packed the stream correctly. The fix registered `valid_out` on the same rising edge and with the same active-low asynchronous reset as `data_out`, preserving the completion expression. It passed all 261 grading samples. Icarus Verilog verified 19 words against a bit-stream scoreboard, including gaps at completion boundaries and reset between edges while valid was high.

In two `TopModule.sv` 8-to-16-bit converter tasks, the pair flag and both output completion conditions were correct. One clocked byte buffer captured during gaps and held on valid cycles. Swapping the ternary arms fixed the capture enable and passed all 141 grading samples. The other buffer already captured while `valid_in` was high, but its combinational block let the second byte overwrite the first before the output edge. Registering the buffer with nonblocking assignments and the same rising edge and active-low asynchronous reset as `data_out` passed all 141 grading samples. Icarus Verilog verified byte order with distinct consecutive bytes and input gaps, as well as asynchronous reset.

Three `TopModule.sv` 1-to-6-bit serial-to-parallel converters shared the same reference timing. `ready_a` resets low and rises on the first clock after reset. At count 5, an idle input holds `data_b` while `valid_b` asserts after the clock edge. In the first task, the shift register captured only when both handshake signals were high, and the counter held only when both were low. The reference changed the hold condition from `~ready_a && ~valid_a` to `~ready_a || ~valid_a`. The submission also tied `ready_a` high and gated `valid_b` with `valid_a`. Its local checks passed under that timing, and grading reported 16 mismatches in 151 samples without identifying individual samples.

In the second task, the counter and shift register already used the correct handshake. The output logic checked count 5, which was unreachable because the counter wrapped at 4 on the fifth accepted bit. Changing only the wrap threshold to 5 matched all 151 grading samples. Icarus Verilog verified all 4096 adjacent word pairs, gaps including a stall before the sixth bit, and asynchronous reset.

In the third task, the handshake, wrap threshold, and data packing were already correct. Combinational `valid_b` went high as soon as the fifth bit brought `cnt` to 5. The reference registered only `valid_b` with active-low asynchronous reset, preserving `cnt == 5` as the pre-edge predicate. On a stall at count 5, the registered flag goes high while the word holds. The submission tied ready high and required `valid_a` for the flag. Its Icarus Verilog scoreboard passed all 4096 adjacent word pairs with gaps under those assumptions, but grading found 16 mismatches in 151 samples.

## A pipelined multiplier drops or duplicates a partial product

Use this when a shift-and-add multiplier gives wrong products for particular multiplier bits.

1. For a multiplier indexed from zero, bit `i` has weight `2**i`, so its partial product shifts the multiplicand left by `i`. Check bit 0 for an unshifted copy and the highest bit for the full shift. Then follow each term through the registered sums. Check both operands of every addition to confirm each term contributes once.
2. To isolate a term in simulation, use a nonzero multiplicand and set one multiplier bit at a time. Expect the multiplicand shifted by that bit index. Then send different operand pairs on consecutive cycles and compare against the products in input order at the expected latency. Assert reset between edges with a result visible and another product pending to verify that both clear.

In the 4-bit unsigned pipelined multiplier in `TopModule.sv`, partial-product generation was correct, but `adder_1` added `temp[2]` twice and omitted `temp[3]`. Replacing the second operand with `temp[3]` matched all 43 grading samples. Icarus Verilog also passed all 256 operand pairs on consecutive cycles and verified two-stage timing and asynchronous reset.

In a separate `TopModule.sv` 4-bit multiplier, both registered sums used the correct terms, but partial-product generation shifted by `i-1`. Bit 0 requested a negative shift and the other bits were each weighted one position too low. Changing only the shift to `i` matched all 43 grading samples. Icarus Verilog verified all 256 operand pairs on consecutive clocks, output on the rising edge after input capture, and asynchronous reset with a product pending.

## An adder loses or creates a carry

Use this when a combinational adder returns the wrong sum or carry-out.

1. Check the generate and propagate expressions before tracing the carry network. Force a carry with both operand bits high and carry-in low. Check propagation with exactly one operand bit high and toggle carry-in. With both operand bits low, carry-out should stay low for either carry-in.
2. If those checks pass, trace the carry feeding each sum bit and the final carry-out. For a small adder, exhaustively compare the concatenated carry-out and sum against a widened addition with both carry-in values.

In the 4-bit `TopModule.sv` adder, the propagate expression, carry recurrence, and sum equations matched the specification. The generate expression duplicated the propagate XOR. The reference changed only `G` to `A_in & B_in`. The submission also implemented the equations using gate primitives and expanded the carries into look-ahead terms. It matched all 425 grading samples, and Icarus Verilog verified all 512 binary input combinations.

## An active-low decoder feeds an incorrect output

Use this when a combinational output is built from decoder lines and asserts for the wrong input combinations.

1. Derive the truth table for each final output from the specification. Map the rows where that output should be high to decoder lines using the actual address pin order. Check the enable and confirm that each address pulls its mapped line low.
2. If the mapping is correct, evaluate the combining expression for one selected row and one unselected row. An enabled active-low decoder has exactly one low line for each binary address. A NAND of all the lines for the desired rows goes high when any of those lines goes low. An OR between products of disjoint groups stays high because at least one group contains only high lines.
3. For a small address space, simulate every binary input and compare all final outputs against the underlying operation. For a one-bit subtractor, compare `{Co, D}` against the two-bit result of `A - B - Ci` with each operand zero-extended.

In the `TopModule.sv` full subtractor, the decoder wiring and borrow equation were already correct. The difference expression used `|` between two pairs of active-low decoder terms, so the final inversion kept `D` low for every binary input. Replacing that `|` with `&` matched the reference and passed all 57 grading samples. Icarus Verilog verified both outputs for all eight input combinations.

## A fractional divider has the right frequency but the wrong pulse width

Use this when a divider alternates between integer periods and its output samples disagree even though the average frequency is correct.

1. Derive the period schedule from the stated ratio and check each mode boundary. If the example's cycle totals conflict with the ratio, calculate the totals from the period lengths and switching point. For 8.7× division, a switch at input cycle 24 in an 87-cycle schedule gives three 8-cycle periods and seven 9-cycle periods. If the counters already produce that schedule, trace the output decoder.
2. For each mode, list the pre-edge counter values that drive the registered output high. With a counter starting at zero, an inclusive comparison against 3 gives four high cycles. Check falling edges within both modes and rising edges across the mode switches. An average-frequency check can pass with either threshold.
3. When the description gives only a frequency ratio, keep pulse width as a separate question. If the two output expressions differ, calculate the waveform for either candidate edit. A scoreboard that assumes one candidate's pulse width can confirm its implementation while leaving the choice between candidates unresolved.

In the `TopModule.sv` 8.7× fractional divider, the reference changed the even-period threshold from `(div_e >> 1) + 1` to `(div_e >> 2) + 1`, matching the existing odd-period formula. This gives four high cycles in both modes. The submission changed the odd-period formula to match the even branch, yielding six high cycles in both modes. Its Icarus Verilog checks passed for the period schedule, asynchronous reset, and its assumed six-cycle width. The grading report found 460 mismatches in 2021 samples.

In another `TopModule.sv` 8.7× divider, the example's cycle totals conflicted with the ratio, but the supplied parameters produced the correct schedule. The even-period formula used `(div_e >> 3) + 1`, giving three high cycles while the odd mode gave four. Changing only the even-period shift to `>> 2` matched all 2021 grading samples. Icarus Verilog checked every output sample across three complete schedules, plus asynchronous reset during a high pulse and the restarted waveform.
