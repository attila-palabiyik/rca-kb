# Gray code conversion

When a counter converts reflected Gray code to binary before incrementing, trace the XOR chain from the most significant bit. Set `binary[MSB] = gray[MSB]`, then use `binary[i] = gray[i] ^ binary[i+1]` for each lower bit. Equivalently, each decoded bit is the reduction XOR of the Gray bits from the most significant bit down to that bit. Convert back with `binary ^ (binary >> 1)`.

## Check the cumulative XOR in the decoder

In the 4-bit Gray counter `TopModule`, the original least significant bit used `gray_wire[0] ^ bin_out[3]`. The supplied reference fix changed that operand to `bin_out[1]` and preserved the existing clocked stages. For a directed check, Gray `0100` should decode to binary `0111`. The original expression produces `0110` because the most significant bit is zero while the adjacent decoded bit is one.

The submitted fix used combinational conversion and increment logic with an explicit two-cycle enable on the output register. All 421 grading samples matched the reference. A local Icarus test of the submission checked each of the 16 values, the hold on alternate edges, wraparound, and asynchronous reset and restart. The reference diff shows that a one-line datapath correction was sufficient for this task.

## Check the shift distance in the encoder

In a second 4-bit Gray counter `TopModule`, the decode chain already used the adjacent decoded bit correctly. The encoder used `bin_add_wire ^ (bin_add_wire >> 2)`. The supplied fix changed only the shift distance to `1`. Binary `0010` is a directed check because the correct encoder produces Gray `0011` and the original encoder produces `0010`.

The submitted fix also made the clocked decode assignments nonblocking and expressed each bit as a reduction XOR over the corresponding Gray slice. It preserved the decode and increment registers in the feedback path and matched all 421 grading samples. The output register taps that feedback path. An Icarus test confirmed that the submitted output held zero on the first rising edge after reset release, advanced on the second, and continued on alternate edges through wraparound and reset restart. Trace the feedback registers before adding a separate enable for the requested cadence. See [Shift-register output timing](shift-register-output-timing.md#aligning-inputs-to-a-registered-stage).

Compare the expected Gray value on every rising edge so the test checks both sequence order and hold cycles. A one-bit-change check alone cannot establish sequence order. See [Shift-register output timing](shift-register-output-timing.md) for checking register cadence independently and [Adder carry generation](adder-carry-generation.md) for isolating datapath dependencies with directed inputs.
