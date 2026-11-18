module TopModule (
    input  wire [3:0] A_in,
    input  wire [3:0] B_in,
    input  wire       C_1,
    output wire [3:0] S,
    output wire       CO
);
    wire [3:0] P, G;
    wire c1, c2, c3;
    wire p0_cin;
    wire p1_g0, p1_p0_cin;
    wire p2_g1, p2_p1_g0, p2_p1_p0_cin;
    wire p3_g2, p3_p2_g1, p3_p2_p1_g0, p3_p2_p1_p0_cin;

    xor propagate_bits [3:0] (P, A_in, B_in);
    and generate_bits  [3:0] (G, A_in, B_in);

    and (p0_cin, P[0], C_1);
    or  (c1, G[0], p0_cin);

    and (p1_g0, P[1], G[0]);
    and (p1_p0_cin, P[1], P[0], C_1);
    or  (c2, G[1], p1_g0, p1_p0_cin);

    and (p2_g1, P[2], G[1]);
    and (p2_p1_g0, P[2], P[1], G[0]);
    and (p2_p1_p0_cin, P[2], P[1], P[0], C_1);
    or  (c3, G[2], p2_g1, p2_p1_g0, p2_p1_p0_cin);

    and (p3_g2, P[3], G[2]);
    and (p3_p2_g1, P[3], P[2], G[1]);
    and (p3_p2_p1_g0, P[3], P[2], P[1], G[0]);
    and (p3_p2_p1_p0_cin, P[3], P[2], P[1], P[0], C_1);
    or  (CO, G[3], p3_g2, p3_p2_g1, p3_p2_p1_g0, p3_p2_p1_p0_cin);

    xor (S[0], P[0], C_1);
    xor (S[1], P[1], c1);
    xor (S[2], P[2], c2);
    xor (S[3], P[3], c3);
endmodule
