# Three-input minimum pipeline and submodule ports

In `TopModule.sv`, two clocked `slave_mod` instances compute the minimum of three unsigned 8-bit inputs. The first instance registers the minimum of `a` and `b`. The original combinational assignment to `c1` let the second instance compare that registered result with `c` from a different sample.

The reference fix changes only the `c1` block. It captures `c` on `posedge clk`, clears `c1` on `negedge rst_n`, and uses nonblocking assignments. The second comparator then receives values captured on the same edge.

The submission registered `c1` correctly but also renamed the existing `slave_mod` ports `a` and `b` to `data_a` and `data_b` to match the prose. It updated both instances in `TopModule`. A local Icarus bench that instantiated only `TopModule` passed directed, randomized, and asynchronous reset checks. Grading failed during compilation with its testbench. The reference preserves the original `slave_mod` port names. The grading report did not include the compiler diagnostic, so the exact error is unconfirmed.

For similar hierarchical RTL fixes, preserve existing named ports when changing timing or datapath logic. Compile a small instance using the original submodule interface if an edit touches its declaration. A top-level simulation can verify timing while missing a named-port compatibility break.
