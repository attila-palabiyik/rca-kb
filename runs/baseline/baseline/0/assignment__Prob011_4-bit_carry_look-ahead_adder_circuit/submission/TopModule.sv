module TopModule(
    input  wire [3:0] A_in,
    input  wire [3:0] B_in,
    input  wire       C_1,
    output wire       CO,
    output wire [3:0] S
);
    wire [3:0] G, P;
    wire [2:0] C;
    wire       carry_1;
    wire [2:1] carry_2;
    wire [3:1] carry_3;
    wire [4:1] carry_4;

    and generate_bits [3:0] (G, A_in, B_in);
    xor propagate_bits [3:0] (P, A_in, B_in);

    // Expand each carry directly in terms of G, P, and the input carry.
    and (carry_1, P[0], C_1);
    or  (C[0], G[0], carry_1);

    and (carry_2[1], P[1], G[0]);
    and (carry_2[2], P[1], P[0], C_1);
    or  (C[1], G[1], carry_2[1], carry_2[2]);

    and (carry_3[1], P[2], G[1]);
    and (carry_3[2], P[2], P[1], G[0]);
    and (carry_3[3], P[2], P[1], P[0], C_1);
    or  (C[2], G[2], carry_3[1], carry_3[2], carry_3[3]);

    and (carry_4[1], P[3], G[2]);
    and (carry_4[2], P[3], P[2], G[1]);
    and (carry_4[3], P[3], P[2], P[1], G[0]);
    and (carry_4[4], P[3], P[2], P[1], P[0], C_1);
    or  (CO, G[3], carry_4[1], carry_4[2], carry_4[3], carry_4[4]);

    xor sum_bits [3:0] (S, P, {C, C_1});
endmodule
