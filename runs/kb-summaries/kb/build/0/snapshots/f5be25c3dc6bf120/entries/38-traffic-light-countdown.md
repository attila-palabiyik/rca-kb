# Traffic light countdown and pedestrian request

TopModule controlled a red, green, and yellow light with an eight-bit countdown. The original state transitions skipped green and exited green into red. Reset cleared all lights, and the extra stages between the internal state and light outputs caused timer reloads and phase transitions to drift apart.

The fix uses the registered one-hot light outputs to track the phase. When the timer expires at 1, the same clock edge advances the phase and loads its duration. Asynchronous reset selects red and loads 10. During green, a sampled request caps the timer at 10 only when it exceeds 10. Icarus Verilog passed 201 checks covering reset, normal cycles, a sustained request, and request behavior at 11, 10, and 9. The initial test-launch command was rejected because of its shell cleanup, so the simulation used a Python-managed temporary directory in the workspace.

This applies to timed FSMs whose visible state and countdown must change on the same edge and whose normal countdown can be shortened by an input.
