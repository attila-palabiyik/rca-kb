module TopModule(
    input  wire [3:0] A_in,
    input  wire [3:0] B_in,
    input  wire       C_1,
    output wire       CO,
    output wire [3:0] S
);
    wire [3:0] G, P;
    wire [2:0] C;
    wire carry0_in;
    wire carry1_g0, carry1_in;
    wire carry2_g1, carry2_g0, carry2_in;
    wire carry3_g2, carry3_g1, carry3_g0, carry3_in;

    and generate_bits[3:0](G, A_in, B_in);
    xor propagate_bits[3:0](P, A_in, B_in);

    // Expand each carry in terms of G, P, and the external carry-in.
    and (carry0_in, P[0], C_1);
    or  (C[0], G[0], carry0_in);

    and (carry1_g0, P[1], G[0]);
    and (carry1_in, P[1], P[0], C_1);
    or  (C[1], G[1], carry1_g0, carry1_in);

    and (carry2_g1, P[2], G[1]);
    and (carry2_g0, P[2], P[1], G[0]);
    and (carry2_in, P[2], P[1], P[0], C_1);
    or  (C[2], G[2], carry2_g1, carry2_g0, carry2_in);

    and (carry3_g2, P[3], G[2]);
    and (carry3_g1, P[3], P[2], G[1]);
    and (carry3_g0, P[3], P[2], P[1], G[0]);
    and (carry3_in, P[3], P[2], P[1], P[0], C_1);
    or  (CO, G[3], carry3_g2, carry3_g1, carry3_g0, carry3_in);

    xor sum_bits[3:0](S, P, {C, C_1});
endmodule
