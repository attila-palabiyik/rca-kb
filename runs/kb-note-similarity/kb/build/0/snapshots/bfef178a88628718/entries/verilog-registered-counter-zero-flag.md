# Trace which counter value each registered output samples

The Verilog `TopModule` decimal up/down counter decoded its current count combinationally. This asserted `zero` in the cycle that `number` became 0 and as soon as reset was released while `number` was still 0. The task specified a pulse in the following cycle and an asynchronous active-low reset that cleared both outputs.

The submitted fix used `zero <= (number == 4'd0)` in the rising-edge block that updated `number`, with both outputs cleared in its reset branch. All 289 grading samples matched. The reference used a separate rising-edge block with the same reset and comparison. Both versions sample the pre-edge count through nonblocking assignments.

For delayed flags, test consecutive edges around the event. Counting up through `9 → 0 → 1` produced `zero = 0` at 0 and `zero = 1` at 1. Counting down through `1 → 0 → 9` produced the pulse at 9. Also check reset release between edges. In this design, `zero` stayed low until the first rising edge after release, then asserted because the sampled reset count was 0.

In a separate `TopModule` decimal up/down counter task, the registered zero flag was already correct. Both mode branches subtracted one on ordinary counts. The reference fix changed only the up branch from `number - 1'd1` to `number + 1'd1`. The submitted fix also made the count literals explicitly four bits wide and matched all 289 grading samples. For bidirectional counters, check an ordinary step in each direction as well as the wraparound. A branch can have the correct terminal count and wrap value while using the wrong arithmetic between them.

## Settable hexadecimal counter with a registered output

In this `TopModule` task, the internal `num` register already counted or loaded `set_num`. The registered `zero` decoded the pre-edge `num`, while the combinational `number` exposed the updated `num`. The submitted fix removed the internal stage, loaded the next count directly into `number`, decoded that same value for `zero`, and asserted `zero` during reset. Its Icarus test passed because it expected that timing and reset value. Grading found 248 mismatches in 273 samples.

The supplied reference only registered `number`. Both outputs then sample the same pre-edge `num`, and asynchronous reset clears both outputs. With `set` low, the first edge after reset releases produces `number = 0, zero = 1` while the internal count becomes 1. The second edge produces `number = 1, zero = 0`. A value loaded into `num` with `set` appears on `number` at the following rising edge, along with its corresponding `zero` value.

When a registered status flag and a direct count output disagree, moving either output can align them while changing the interface timing in different ways. Trace which register each output samples and check the first two edges after reset, the edge that loads a new value, and the following edge. The flag/count relationship alone cannot distinguish these implementations during ordinary operation. Check the reset values separately.
