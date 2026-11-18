# Registered comparisons in a shift-register sequence detector

This entry records the grading outcome for the 011XXX110 detector in entry 2. The submitted implementation differed from the reference on 16 of 237 samples. Its local Icarus tests passed because they expected a match on the edge that received the final bit and required nine real samples after reset.

The original prefix comparison was combinational, so it saw the shift register after the edge. The suffix comparison was clocked and saw the shift register before the edge. The reference patch changes only the prefix check to an active-low asynchronously reset clocked block using nonblocking assignments. Both comparisons then read the same pre-edge window. The output is the AND of their registered results, so a full sequence produces a match on the rising edge after its last bit is sampled. The reference also compares the zero-initialized window from the first clock after reset without a sample-count gate. For example, the reset zero can supply the leading bit for a pre-edge window that contains eight real samples of 11XXX110.

The submitted implementation compared the incoming window and added a sample counter. Both choices changed behavior relative to the reference. The grading result reports the aggregate mismatch count, so it does not establish how many samples differed for each reason.

For debug tasks involving mixed combinational and registered checks, start by tracing the pre-edge and post-edge values of the existing clocked path. Use directed checks immediately before, on, and after the final input edge, and test reset padding explicitly before adding a startup guard. Preserve the established cycle timing and reset semantics when the requested repair can be confined to the misaligned check.
