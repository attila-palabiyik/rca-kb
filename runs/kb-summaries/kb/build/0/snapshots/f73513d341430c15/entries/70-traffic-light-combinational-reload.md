# Traffic light countdown with combinational light outputs

TopModule had the correct red, green, and yellow successor order and active-low edge-detection predicates for timer reloads. However, each public light was a combinational mirror of its intermediate register, so the supposed edge detector did not see different values at a settled clock edge. Reset also forced all public lights off despite the specification requiring red and a countdown of 10.

The fix uses the registered one-hot light outputs as the phase and updates the phase and eight-bit countdown together. Reset asynchronously selects red and loads 10. When the countdown reaches 1, the next rising edge selects the next light and loads its full duration. A request sampled during green caps values above 10. A request held through red first takes effect on the edge after green begins. No repair attempt failed. An independent Icarus simulation passed 3,350 checks covering normal cycles, reset between edges, requests at every green count, and a held request across phase boundaries.

This applies to timed state machines with a counter reload based on a purported previous value. Check whether the two signals compared by the edge detector actually represent different sampled cycles.
