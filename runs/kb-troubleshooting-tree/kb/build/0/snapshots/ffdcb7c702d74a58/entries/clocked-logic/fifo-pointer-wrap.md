# Check that the FIFO wrap bit toggles when its address rolls over

**Check** each pointer that uses a RAM index and a wrap bit. Trace an accepted operation at the last valid index, `DEPTH - 1`. On that edge the index should return to zero and the wrap bit should toggle.

- **The index rolls over but the wrap bit stays unchanged, or they change on different edges.** Make both use the last valid index as their rollover condition. Verify that a fill followed by a drain asserts full and then empty, repeating across another lap.
- **Both parts wrap together on each pointer.** At equal indices, check whether matching wrap bits report empty and differing wrap bits report full. If the trace stalls before rollover, [check the FIFO port enable](fifo-port-enable.md).

**Observed in `TopModule.sv`**, a synchronous FIFO with dual-port RAM and a read-pointer rollover bug. The read index returned to zero at `DEPTH - 1`, so the wrap-bit comparison against `DEPTH` was unreachable. The reference changed that comparison to `DEPTH - 1` and retained the original occupancy arithmetic. The submission also switched to direct pointer comparisons, gated both RAM enables during reset, and supported depth one. It matched all 327 graded samples. The reference fix shows that the wrap-bit comparison alone corrected the reported bug.
