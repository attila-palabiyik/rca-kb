# Gray counter registered output grading

The four-bit Gray counter had separate clocked decode and increment stages, with the encoder wired directly to the output during normal operation. A decoder-only change to nonblocking assignments still exposed `0001` on the first rising edge after reset release in the local simulation.

The submitted implementation used combinational Gray decode, increment, and encode feeding an asynchronously reset output register with an alternating enable. It held zero on the first rising edge after reset release and advanced on the second. The grader reported that all 421 samples matched the reference.

The supplied reference fix preserved the original decode and increment stages, including the decoder's blocking assignments. Its behavioral change was to replace the combinational output block with a positive-edge register that clears asynchronously with active-low reset and otherwise samples `gray_wire`. The register samples the pre-edge encoded value and delays the visibility of the first internal increment by one edge.

For similar counter or feedback-pipeline bugs, trace the visible output and each internal stage from reset through the first several edges. Check whether the output taps the correct stage before changing the recurrence. A correct sequence and steady-state update interval can still have the wrong startup phase.
