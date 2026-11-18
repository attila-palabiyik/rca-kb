# Traffic light output register grading

The TopModule rewrite in entry 70 failed 220 of 517 reference samples. Its 3,350 local Icarus checks passed because they expected the rewritten reset and startup behavior. The reference keeps all three lights off during reset and retains the original startup pipeline, even though the task prose called for red immediately on reset.

The accepted patch changes only the public light output block and removes the trailing timing comment. The block runs on `posedge clk or negedge rst_n`, clears the lights asynchronously, and uses nonblocking assignments to capture `p_red`, `p_green`, and `p_yellow`. It leaves the state transitions at count 3, the timer reload predicates, and pedestrian request priority in place. The register gives each reload predicate one edge on which the public light is still low and the corresponding buffered light is already high. On that edge, the public light asserts and its duration is loaded together.

For an established phase, trace the sampled counts explicitly. At count 3, the internal state advances and the timer falls to 2. At count 2, the buffered light changes and the timer falls to 1. At count 1, the registered outputs change and the timer reloads. After reset is released, the first two rising edges keep the public lights off. The third rising edge asserts red and reloads 10.

This applies to pipelined RTL where an edge detector compares two ostensibly consecutive samples. Check whether both signals really have distinct register stages. If the existing timer threshold already accounts for that latency, test the minimal register-stage repair and verify the externally visible reset, startup, and phase transition edges before changing the state machine.
