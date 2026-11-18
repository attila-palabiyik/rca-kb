# Serial packer output valid register grading result

The six-bit serial packer submission differed from the reference on 16 of 151 samples. The supplied fix changes only the `valid_b` block. It replaces the combinational count decode with a rising-edge register, clears it on active-low asynchronous reset, and assigns `valid_b <= cnt == 5` on each rising edge outside reset.

The reference preserves registered `ready_a`, which is low during reset and rises on the first clock after release. The counter and input shift register still use the ready-valid handshake. At count five, `valid_b` registers high even if `valid_a` is low, while `data_b` holds until a valid sixth bit arrives. The submitted implementation tied ready high and gated the valid pulse on acceptance of the sixth bit. Its Icarus tests encoded those assumptions. The grading report gave the mismatch count without identifying individual samples.

For similar RTL debugging tasks, trace the existing timing and try the local register change when a combinational decode leads a clocked output by a cycle. Check reset release and a stall at the terminal count separately. These cases distinguish the reference's registered count decode from a redesign that signals completion only on a transfer. Entry 72 describes the submission before grading.
