# FIFO pointer clocking

When a synchronous FIFO uses a RAM that samples its address and enable on the rising edge, advance the stored pointer on that same edge with a nonblocking assignment. The RAM samples the current address, and the pointer advances afterward for the next accepted request. Keep the pointer's next-value calculation combinational and update the pointer only when the corresponding RAM enable is asserted.

In the dual-port RAM FIFO `TopModule` task, the write pointer assigned its own computed next value in `always @(*)`. This fed the stored pointer back into the address and full-flag logic without a clock edge to control when it advanced. The supplied correct fix put the write pointer in `always @(posedge clk or negedge rst_n)` with nonblocking assignments, matching the existing read pointer, and retained the original flag arithmetic and RAM enables. The submitted patch also decoded flags directly from the address and wrap bits, gated RAM enables during reset, and handled the supplied RAM's address-port width at depth one. All 327 grading samples matched. The supplied fix establishes that the pointer block change alone was sufficient for this task.

To check the clock boundary, assert a request between rising edges and confirm that the pointer and flags hold until the next edge. Verify data order through wraparound and exercise simultaneous requests with the FIFO empty, partially filled, and full. Use the design's enable rules as the expected behavior at each boundary.

## Check the enable polarity

In a separate synchronous dual-port RAM FIFO `TopModule` task, the write pointer already advanced on the correct edge, but `wenc = winc & wfull` blocked the first write after reset and qualified writes only while full. That enable controlled both the RAM write and the write pointer, so the empty FIFO could never fill. The supplied functional fix was `wenc = winc & (!wfull)`. The submitted patch also compared pointers directly for the flags, gated both RAM enables during reset, and supported depth one. All 327 grading samples matched. The reference establishes that correcting the write-enable polarity was sufficient.

After reset, request one write and check that `rempty` clears on the rising edge. Fill the FIFO, attempt one extra write, and drain it to verify that the oldest word was preserved. With both requests asserted, the reference accepts only the write at empty, both operations at partial occupancy, and only the read at full. Check acceptance against the flags just before the rising edge.

## Check that the wrap bit toggles with the address

In the synchronous dual-port RAM FIFO `TopModule` task with a faulty read-pointer wrap, the low address returned to zero at `DEPTH - 1`, but the wrap bit checked for `DEPTH`. The read address never reached that comparison value, so the bit never toggled. After a fill and drain from reset, the low addresses matched while the wrap bits differed, leaving the flags at full after the final read. The supplied functional fix changed the read wrap-bit comparison to `DEPTH - 1`, the same threshold used for the low address and the write pointer.

The submitted patch used a shared last-address constant, compared pointers directly for the flags, gated RAM enables during reset, and supported depth one with a one-bit RAM address. All 327 grading samples matched. The supplied fix establishes that correcting the read wrap threshold was sufficient. Separate Icarus queue checks passed at depths 1, 2, 3, 16, and 19.

For a FIFO with a wrap bit above the RAM address, fill and drain one complete buffer and check the flags immediately after the last accepted read. Repeat with a non-power-of-two depth when supported. Confirm that each pointer changes its wrap bit on the same accepted transfer that moves its low address from `DEPTH - 1` to zero. For another zero-based boundary comparison, see [Fractional divider duty cycle](fractional-divider-duty-cycle.md).

For another example of sampling pre-edge register values, see [Shift-register output timing](shift-register-output-timing.md).

For a stream packer whose input counter must advance on the same transfer as its shift register, see [Width converter output validity](width-converter-valid.md#count-accepted-input-transfers).

For a stream packer whose counter wraps before the output decode can fire, see [Width converter output validity](width-converter-valid.md#check-that-the-counter-reaches-the-output-boundary).
