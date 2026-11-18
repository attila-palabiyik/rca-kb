module TopModule(
    input  wire [3:0] A_in,
    input  wire [3:0] B_in,
    input  wire       C_1,
    output wire       CO,
    output wire [3:0] S
);
    wire [3:0] G, P;
    wire [2:0] C;
    wire carry0_from_in;
    wire carry1_from_g0, carry1_from_in;
    wire carry2_from_g1, carry2_from_g0, carry2_from_in;
    wire carry3_from_g2, carry3_from_g1, carry3_from_g0, carry3_from_in;

    and generate_bit [3:0] (G, A_in, B_in);
    xor propagate_bit [3:0] (P, A_in, B_in);

    // Expand each carry in terms of G, P, and the input carry.
    and (carry0_from_in, P[0], C_1);
    or  (C[0], G[0], carry0_from_in);

    and (carry1_from_g0, P[1], G[0]);
    and (carry1_from_in, P[1], P[0], C_1);
    or  (C[1], G[1], carry1_from_g0, carry1_from_in);

    and (carry2_from_g1, P[2], G[1]);
    and (carry2_from_g0, P[2], P[1], G[0]);
    and (carry2_from_in, P[2], P[1], P[0], C_1);
    or  (C[2], G[2], carry2_from_g1, carry2_from_g0, carry2_from_in);

    and (carry3_from_g2, P[3], G[2]);
    and (carry3_from_g1, P[3], P[2], G[1]);
    and (carry3_from_g0, P[3], P[2], P[1], G[0]);
    and (carry3_from_in, P[3], P[2], P[1], P[0], C_1);
    or  (CO, G[3], carry3_from_g2, carry3_from_g1, carry3_from_g0, carry3_from_in);

    xor sum_bit [3:0] (S, P, {C, C_1});
endmodule
