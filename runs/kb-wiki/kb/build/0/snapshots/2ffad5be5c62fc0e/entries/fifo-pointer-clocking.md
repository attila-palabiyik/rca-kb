# FIFO pointer clocking

When a synchronous FIFO uses a RAM that samples its address and enable on the rising edge, advance the stored pointer on that same edge with a nonblocking assignment. The RAM samples the current address, and the pointer advances afterward for the next accepted request. Keep the pointer's next-value calculation combinational and update the pointer only when the corresponding RAM enable is asserted.

In the dual-port RAM FIFO `TopModule` task, the write pointer assigned its own computed next value in `always @(*)`. This fed the stored pointer back into the address and full-flag logic without a clock edge to control when it advanced. The supplied correct fix put the write pointer in `always @(posedge clk or negedge rst_n)` with nonblocking assignments, matching the existing read pointer, and retained the original flag arithmetic and RAM enables. The submitted patch also decoded flags directly from the address and wrap bits, gated RAM enables during reset, and handled the supplied RAM's address-port width at depth one. All 327 grading samples matched. The supplied fix establishes that the pointer block change alone was sufficient for this task.

To check the clock boundary, assert a request between rising edges and confirm that the pointer and flags hold until the next edge. Verify data order through wraparound and exercise simultaneous requests with the FIFO empty, partially filled, and full. Use the design's enable rules as the expected behavior at each boundary.

For another example of sampling pre-edge register values, see [Shift-register output timing](shift-register-output-timing.md).

For a stream packer whose input counter must advance on the same transfer as its shift register, see [Width converter output validity](width-converter-valid.md#count-accepted-input-transfers).
