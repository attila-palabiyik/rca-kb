module TopModule(
    input  wire [3:0] A_in,
    input  wire [3:0] B_in,
    input  wire       C_1,
    output wire       CO,
    output wire [3:0] S
);
    wire [3:0] G, P;
    wire [2:0] C;
    wire       c0_from_input;
    wire [1:0] c1_terms;
    wire [2:0] c2_terms;
    wire [3:0] co_terms;

    and generate_bit[3:0] (G, A_in, B_in);
    xor propagate_bit[3:0] (P, A_in, B_in);

    // Expand each carry directly from the generate and propagate signals.
    and (c0_from_input, P[0], C_1);
    or  (C[0], G[0], c0_from_input);

    and (c1_terms[0], P[1], G[0]);
    and (c1_terms[1], P[1], P[0], C_1);
    or  (C[1], G[1], c1_terms[0], c1_terms[1]);

    and (c2_terms[0], P[2], G[1]);
    and (c2_terms[1], P[2], P[1], G[0]);
    and (c2_terms[2], P[2], P[1], P[0], C_1);
    or  (C[2], G[2], c2_terms[0], c2_terms[1], c2_terms[2]);

    and (co_terms[0], P[3], G[2]);
    and (co_terms[1], P[3], P[2], G[1]);
    and (co_terms[2], P[3], P[2], P[1], G[0]);
    and (co_terms[3], P[3], P[2], P[1], P[0], C_1);
    or  (CO, G[3], co_terms[0], co_terms[1], co_terms[2], co_terms[3]);

    xor sum_bit[3:0] (S, P, {C, C_1});
endmodule
