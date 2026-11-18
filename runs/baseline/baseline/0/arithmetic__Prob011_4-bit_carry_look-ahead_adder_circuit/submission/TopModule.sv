module TopModule(
    input  wire [3:0] A_in,
    input  wire [3:0] B_in,
    input  wire       C_1,
    output wire       CO,
    output wire [3:0] S
);
    wire [3:0] G, P;
    wire [2:0] C;
    wire       c0_p0;
    wire [1:0] c1_terms;
    wire [2:0] c2_terms;
    wire [3:0] co_terms;

    and generate_bits [3:0] (G, A_in, B_in);
    xor propagate_bits [3:0] (P, A_in, B_in);

    // Expand each carry in terms of G, P, and the input carry.
    and carry0_p0 (c0_p0, P[0], C_1);
    or  carry0    (C[0], G[0], c0_p0);

    and carry1_g0 (c1_terms[0], P[1], G[0]);
    and carry1_p0 (c1_terms[1], P[1], P[0], C_1);
    or  carry1    (C[1], G[1], c1_terms[0], c1_terms[1]);

    and carry2_g1 (c2_terms[0], P[2], G[1]);
    and carry2_g0 (c2_terms[1], P[2], P[1], G[0]);
    and carry2_p0 (c2_terms[2], P[2], P[1], P[0], C_1);
    or  carry2    (C[2], G[2], c2_terms[0], c2_terms[1], c2_terms[2]);

    and carry3_g2 (co_terms[0], P[3], G[2]);
    and carry3_g1 (co_terms[1], P[3], P[2], G[1]);
    and carry3_g0 (co_terms[2], P[3], P[2], P[1], G[0]);
    and carry3_p0 (co_terms[3], P[3], P[2], P[1], P[0], C_1);
    or  carry3    (CO, G[3], co_terms[0], co_terms[1], co_terms[2], co_terms[3]);

    xor sum_bits [3:0] (S, P, {C, C_1});
endmodule
