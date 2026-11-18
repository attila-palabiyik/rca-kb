# Check each state's output assignments

**Check** the full set of outputs assigned in each state against that state's intended output pattern. Include buffered phase bits that feed edge detection or timer reloads. When outputs must be mutually exclusive, check both which bit is asserted and which bits are cleared.

- **A state asserts an extra output or omits a required one.** Correct the assignment in that branch. Trace the buffered and visible outputs across phase entry, and check which reload guard wins if multiple guards can be true. Verify the outgoing phase's last visible count and the incoming phase's first count.
- **Every state's output pattern matches, but the visible output is early or late.** Go to [the registered output timing check](transition-output-timing.md).

**Observed in `TopModule.sv`**, a traffic-light FSM with correct transition destinations. The red state set both `p_red` and `p_green` to 1. On the first red entry after reset, both entry guards can fire, and the green reload has priority over the red reload. The grading reference changed `p_green` to 0 in the red branch and removed the stale timing comment. It retained the count-3 transition trigger, two registered output stages, and the idle reset with all lights off, even though the prose called for red on reset.

The submitted rewrite used the light outputs as the state, switched phases at count 1, and asserted red on reset. It passed local tests based on the prose and differed from the reference on 220 of 517 samples. The aggregate does not identify how many mismatches came from each change.
