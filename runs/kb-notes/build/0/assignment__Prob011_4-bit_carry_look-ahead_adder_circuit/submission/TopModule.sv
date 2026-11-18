module TopModule(
    input  wire [3:0] A_in,
    input  wire [3:0] B_in,
    input  wire       C_1,
    output wire       CO,
    output wire [3:0] S
);
    wire [3:0] G, P;
    wire [2:0] C;
    wire carry0_term;
    wire [1:0] carry1_terms;
    wire [2:0] carry2_terms;
    wire [3:0] carry3_terms;

    and generate_bits[3:0] (G, A_in, B_in);
    xor propagate_bits[3:0] (P, A_in, B_in);

    // Expand each carry so it can be computed directly from G, P, and C_1.
    and (carry0_term, P[0], C_1);
    or  (C[0], G[0], carry0_term);

    and (carry1_terms[0], P[1], G[0]);
    and (carry1_terms[1], P[1], P[0], C_1);
    or  (C[1], G[1], carry1_terms[0], carry1_terms[1]);

    and (carry2_terms[0], P[2], G[1]);
    and (carry2_terms[1], P[2], P[1], G[0]);
    and (carry2_terms[2], P[2], P[1], P[0], C_1);
    or  (C[2], G[2], carry2_terms[0], carry2_terms[1], carry2_terms[2]);

    and (carry3_terms[0], P[3], G[2]);
    and (carry3_terms[1], P[3], P[2], G[1]);
    and (carry3_terms[2], P[3], P[2], P[1], G[0]);
    and (carry3_terms[3], P[3], P[2], P[1], P[0], C_1);
    or  (CO, G[3], carry3_terms[0], carry3_terms[1], carry3_terms[2], carry3_terms[3]);

    xor sum_bits[3:0] (S, P, {C, C_1});
endmodule
