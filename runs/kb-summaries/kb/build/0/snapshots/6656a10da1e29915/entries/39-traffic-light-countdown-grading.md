# Grading follow-up for the traffic light countdown

The submitted TopModule failed 220 of 517 reference samples. It replaced the original registered light pipeline with a controller that asserted red immediately on reset and loaded each interval as the light changed. Its 201 local checks verified the timing chosen for the rewrite.

The supplied reference fix changes two successors at `cnt == 3`: red goes to green, and green goes to yellow. Yellow already goes to red. It also removes the trailing explanatory comment. The reference preserves the reset to idle with all lights off, the startup delay, the intermediate light registers, the timer reload logic, and the pedestrian request logic.

Tracing the retained pipeline explains the threshold of 3. On the edge that samples 3, the internal state advances and the timer reaches 2. On the edge that samples 2, the next light is buffered and the timer reaches 1. On the edge that samples 1, the visible light changes and its timer reloads.

For wrong-successor bugs in registered FSMs, trace the state, intermediate registers, and visible outputs edge by edge before changing transition thresholds. Exercise the existing startup and output latency in local tests when the repair targets the state sequence.
