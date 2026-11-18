module TopModule(
    input  wire [3:0] A_in,
    input  wire [3:0] B_in,
    input  wire       C_1,
    output wire       CO,
    output wire [3:0] S
);
    wire [3:0] G, P;
    wire [2:0] C;
    wire carry_0_in;
    wire carry_1_g0, carry_1_in;
    wire carry_2_g1, carry_2_g0, carry_2_in;
    wire carry_3_g2, carry_3_g1, carry_3_g0, carry_3_in;

    and generate_bits[3:0] (G, A_in, B_in);
    xor propagate_bits[3:0] (P, A_in, B_in);

    // Expand each carry directly from G, P, and the input carry.
    and (carry_0_in, P[0], C_1);
    or  (C[0], G[0], carry_0_in);

    and (carry_1_g0, P[1], G[0]);
    and (carry_1_in, P[1], P[0], C_1);
    or  (C[1], G[1], carry_1_g0, carry_1_in);

    and (carry_2_g1, P[2], G[1]);
    and (carry_2_g0, P[2], P[1], G[0]);
    and (carry_2_in, P[2], P[1], P[0], C_1);
    or  (C[2], G[2], carry_2_g1, carry_2_g0, carry_2_in);

    and (carry_3_g2, P[3], G[2]);
    and (carry_3_g1, P[3], P[2], G[1]);
    and (carry_3_g0, P[3], P[2], P[1], G[0]);
    and (carry_3_in, P[3], P[2], P[1], P[0], C_1);
    or  (CO, G[3], carry_3_g2, carry_3_g1, carry_3_g0, carry_3_in);

    xor sum_bits[3:0] (S, P, {C, C_1});
endmodule
