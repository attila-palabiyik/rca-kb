module TopModule(
    input  wire [3:0] A_in,
    input  wire [3:0] B_in,
    input  wire       C_1,
    output wire       CO,
    output wire [3:0] S
);
    wire [3:0] G, P;
    wire [3:1] C;
    wire c1_from_cin;
    wire c2_from_g0, c2_from_cin;
    wire c3_from_g1, c3_from_g0, c3_from_cin;
    wire co_from_g2, co_from_g1, co_from_g0, co_from_cin;

    and generate_bit[3:0] (G, A_in, B_in);
    xor propagate_bit[3:0] (P, A_in, B_in);

    // Expand each carry directly from G, P, and the external carry-in.
    and (c1_from_cin, P[0], C_1);
    or  (C[1], G[0], c1_from_cin);

    and (c2_from_g0,  P[1], G[0]);
    and (c2_from_cin, P[1], P[0], C_1);
    or  (C[2], G[1], c2_from_g0, c2_from_cin);

    and (c3_from_g1,  P[2], G[1]);
    and (c3_from_g0,  P[2], P[1], G[0]);
    and (c3_from_cin, P[2], P[1], P[0], C_1);
    or  (C[3], G[2], c3_from_g1, c3_from_g0, c3_from_cin);

    and (co_from_g2,  P[3], G[2]);
    and (co_from_g1,  P[3], P[2], G[1]);
    and (co_from_g0,  P[3], P[2], P[1], G[0]);
    and (co_from_cin, P[3], P[2], P[1], P[0], C_1);
    or  (CO, G[3], co_from_g2, co_from_g1, co_from_g0, co_from_cin);

    xor sum_bit[3:0] (S, P, {C, C_1});
endmodule
