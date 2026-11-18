module TopModule(
    input  wire [3:0] A_in,
    input  wire [3:0] B_in,
    input  wire       C_1,
    output wire       CO,
    output wire [3:0] S
);
    wire [3:0] G, P;
    wire [2:0] C;
    wire [3:0] carry_in_terms;
    wire [2:0] g0_terms;
    wire [1:0] g1_terms;
    wire       g2_term;

    and generate_bits[3:0] (G, A_in, B_in);
    xor propagate_bits[3:0] (P, A_in, B_in);

    and (carry_in_terms[0], P[0], C_1);
    or  (C[0], G[0], carry_in_terms[0]);

    and (g0_terms[0], P[1], G[0]);
    and (carry_in_terms[1], P[1], P[0], C_1);
    or  (C[1], G[1], g0_terms[0], carry_in_terms[1]);

    and (g1_terms[0], P[2], G[1]);
    and (g0_terms[1], P[2], P[1], G[0]);
    and (carry_in_terms[2], P[2], P[1], P[0], C_1);
    or  (C[2], G[2], g1_terms[0], g0_terms[1], carry_in_terms[2]);

    and (g2_term, P[3], G[2]);
    and (g1_terms[1], P[3], P[2], G[1]);
    and (g0_terms[2], P[3], P[2], P[1], G[0]);
    and (carry_in_terms[3], P[3], P[2], P[1], P[0], C_1);
    or  (CO, G[3], g2_term, g1_terms[1], g0_terms[2], carry_in_terms[3]);

    xor sum_bits[3:0] (S, P, {C, C_1});
endmodule
