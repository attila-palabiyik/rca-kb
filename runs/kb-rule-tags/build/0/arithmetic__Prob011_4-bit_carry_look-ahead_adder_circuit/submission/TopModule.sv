module TopModule(
    input  wire [3:0] A_in,
    input  wire [3:0] B_in,
    input  wire       C_1,
    output wire       CO,
    output wire [3:0] S
);
    wire [3:0] G, P;
    wire [2:0] C;
    wire       carry_0_term;
    wire [1:0] carry_1_terms;
    wire [2:0] carry_2_terms;
    wire [3:0] carry_out_terms;

    and (G[0], A_in[0], B_in[0]);
    and (G[1], A_in[1], B_in[1]);
    and (G[2], A_in[2], B_in[2]);
    and (G[3], A_in[3], B_in[3]);

    xor (P[0], A_in[0], B_in[0]);
    xor (P[1], A_in[1], B_in[1]);
    xor (P[2], A_in[2], B_in[2]);
    xor (P[3], A_in[3], B_in[3]);

    // Expand each carry in terms of generate, propagate, and carry-in.
    and (carry_0_term, P[0], C_1);
    or  (C[0], G[0], carry_0_term);

    and (carry_1_terms[0], P[1], G[0]);
    and (carry_1_terms[1], P[1], P[0], C_1);
    or  (C[1], G[1], carry_1_terms[0], carry_1_terms[1]);

    and (carry_2_terms[0], P[2], G[1]);
    and (carry_2_terms[1], P[2], P[1], G[0]);
    and (carry_2_terms[2], P[2], P[1], P[0], C_1);
    or  (C[2], G[2], carry_2_terms[0], carry_2_terms[1], carry_2_terms[2]);

    and (carry_out_terms[0], P[3], G[2]);
    and (carry_out_terms[1], P[3], P[2], G[1]);
    and (carry_out_terms[2], P[3], P[2], P[1], G[0]);
    and (carry_out_terms[3], P[3], P[2], P[1], P[0], C_1);
    or  (CO, G[3], carry_out_terms[0], carry_out_terms[1],
             carry_out_terms[2], carry_out_terms[3]);

    xor (S[0], P[0], C_1);
    xor (S[1], P[1], C[0]);
    xor (S[2], P[2], C[1]);
    xor (S[3], P[3], C[2]);
endmodule
