# Traffic light transitions and countdown

TopModule pipelined its state and light outputs and tried to compensate by changing internal state at count 3. Reset left the lights dark, and the green reload condition could keep reloading the timer during green.

The fix uses the registered one-hot light outputs as the state and updates them and the countdown on the same edge. Asynchronous reset immediately loads red and 10. At count 1, the next light and its duration are loaded together. A request sampled during green caps the timer at 10 when its current value exceeds 10. A request held through red takes effect at the first edge sampling green.

An independent Icarus test checked every count in a complete normal cycle, a held request, a request at count 11 and at 10, and asynchronous reset during green. The first test launch was rejected because of its shell cleanup command. Running the test in a workspace-local Python temporary directory worked and cleaned up the test files.

For timed one-hot controllers, verify the light and countdown together at every boundary and check the request threshold on consecutive edges.
