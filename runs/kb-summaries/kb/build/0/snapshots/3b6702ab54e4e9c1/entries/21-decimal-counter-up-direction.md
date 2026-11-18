# Decimal up/down counter increments in up mode

TopModule already registered its delayed zero flag and handled both decimal wrap boundaries. The bug was the arithmetic in the up branch. With mode high and the count below 9, it subtracted one. Starting at zero therefore produced 15 in the 4-bit count.

The submitted fix changed that branch to add `4'd1`. The reference used `1'd1` as the addend. All 289 graded samples matched. A temporary Icarus Verilog test also passed every decimal starting count in both directions and checked wraparound, the one-cycle delay of zero, and asynchronous reset. The one-line change passed on the first attempt.

For counters with separate direction and wrap branches, exercise the ordinary arithmetic and the wrap in each direction. Check registered status outputs using the count immediately before the edge. Here the edge entering zero left the flag low, and the edge leaving zero asserted it.
