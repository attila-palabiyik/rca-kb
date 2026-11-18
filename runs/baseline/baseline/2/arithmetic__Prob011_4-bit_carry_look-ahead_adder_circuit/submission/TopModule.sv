module TopModule(
    input  wire [3:0] A_in,
    input  wire [3:0] B_in,
    input  wire       C_1,
    output wire       CO,
    output wire [3:0] S
);
    wire [3:0] G, P;
    wire [2:0] C;
    wire       carry0_term;
    wire [1:0] carry1_terms;
    wire [2:0] carry2_terms;
    wire [3:0] carry3_terms;

    and gen0(G[0], A_in[0], B_in[0]);
    and gen1(G[1], A_in[1], B_in[1]);
    and gen2(G[2], A_in[2], B_in[2]);
    and gen3(G[3], A_in[3], B_in[3]);

    xor prop0(P[0], A_in[0], B_in[0]);
    xor prop1(P[1], A_in[1], B_in[1]);
    xor prop2(P[2], A_in[2], B_in[2]);
    xor prop3(P[3], A_in[3], B_in[3]);

    // Expand each carry directly in terms of G, P, and the input carry.
    and carry0_in(carry0_term, P[0], C_1);
    or  carry0(C[0], G[0], carry0_term);

    and carry1_g0(carry1_terms[0], P[1], G[0]);
    and carry1_in(carry1_terms[1], P[1], P[0], C_1);
    or  carry1(C[1], G[1], carry1_terms[0], carry1_terms[1]);

    and carry2_g1(carry2_terms[0], P[2], G[1]);
    and carry2_g0(carry2_terms[1], P[2], P[1], G[0]);
    and carry2_in(carry2_terms[2], P[2], P[1], P[0], C_1);
    or  carry2(C[2], G[2], carry2_terms[0], carry2_terms[1], carry2_terms[2]);

    and carry3_g2(carry3_terms[0], P[3], G[2]);
    and carry3_g1(carry3_terms[1], P[3], P[2], G[1]);
    and carry3_g0(carry3_terms[2], P[3], P[2], P[1], G[0]);
    and carry3_in(carry3_terms[3], P[3], P[2], P[1], P[0], C_1);
    or  carry3(CO, G[3], carry3_terms[0], carry3_terms[1], carry3_terms[2], carry3_terms[3]);

    xor sum0(S[0], P[0], C_1);
    xor sum1(S[1], P[1], C[0]);
    xor sum2(S[2], P[2], C[1]);
    xor sum3(S[3], P[3], C[2]);
endmodule
