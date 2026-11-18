# Check next-state branches against the transition table

**Check** the destination for each input value in every state's next-state logic. When a row specifies different destinations, check for a copied destination in both branches of a conditional.

- **A destination differs from the table.** Correct the mismatched branch. Exercise each input from the affected state on separate visits, and check the destination after the clock edge. A Moore output can have the same value in both destinations, so check the state or follow it until the output distinguishes the paths.
- **All destinations match.** Trace which states assert each Moore output. If reset or output timing is in question, go to [the output decode and reset check](output-decode-reset.md).

**Observed in `TopModule.sv`**, a five-state Moore FSM with a wrong transition out of `S4`. Both branches selected `S1`, while the table specified `S1` for `data=1` and `S0` for `data=0`. Both destinations deasserted `flag`, so checking only that `flag` fell after leaving `S4` would miss the wrong destination. Changing only the `data=0` branch matched all 261 reference samples.
