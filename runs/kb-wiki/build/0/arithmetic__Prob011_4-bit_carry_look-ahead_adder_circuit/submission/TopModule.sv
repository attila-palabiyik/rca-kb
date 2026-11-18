module TopModule(
    input  wire [3:0] A_in,
    input  wire [3:0] B_in,
    input  wire       C_1,
    output wire       CO,
    output wire [3:0] S
);
    wire [3:0] G, P;
    wire [2:0] C;
    wire c0_p0;
    wire c1_g0, c1_p0;
    wire c2_g1, c2_g0, c2_p0;
    wire c3_g2, c3_g1, c3_g0, c3_p0;

    and (G[0], A_in[0], B_in[0]);
    and (G[1], A_in[1], B_in[1]);
    and (G[2], A_in[2], B_in[2]);
    and (G[3], A_in[3], B_in[3]);

    xor (P[0], A_in[0], B_in[0]);
    xor (P[1], A_in[1], B_in[1]);
    xor (P[2], A_in[2], B_in[2]);
    xor (P[3], A_in[3], B_in[3]);

    // Expand each carry in terms of G, P, and the input carry.
    and (c0_p0, P[0], C_1);
    or  (C[0], G[0], c0_p0);

    and (c1_g0, P[1], G[0]);
    and (c1_p0, P[1], P[0], C_1);
    or  (C[1], G[1], c1_g0, c1_p0);

    and (c2_g1, P[2], G[1]);
    and (c2_g0, P[2], P[1], G[0]);
    and (c2_p0, P[2], P[1], P[0], C_1);
    or  (C[2], G[2], c2_g1, c2_g0, c2_p0);

    and (c3_g2, P[3], G[2]);
    and (c3_g1, P[3], P[2], G[1]);
    and (c3_g0, P[3], P[2], P[1], G[0]);
    and (c3_p0, P[3], P[2], P[1], P[0], C_1);
    or  (CO, G[3], c3_g2, c3_g1, c3_g0, c3_p0);

    xor (S[0], P[0], C_1);
    xor (S[1], P[1], C[0]);
    xor (S[2], P[2], C[1]);
    xor (S[3], P[3], C[2]);
endmodule
