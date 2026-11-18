module TopModule(
    input wire [3:0] A_in,
    input wire [3:0] B_in,
    input wire C_1,
    output wire CO,
    output wire [3:0] S
);
    wire [3:0] G, P;
    wire [2:0] carry;
    wire c1_term;
    wire [1:0] c2_terms;
    wire [2:0] c3_terms;
    wire [3:0] c4_terms;

    and generate_bits[3:0](G, A_in, B_in);
    xor propagate_bits[3:0](P, A_in, B_in);

    // Expand each carry so it can be computed independently.
    and (c1_term, P[0], C_1);
    or  (carry[0], G[0], c1_term);

    and (c2_terms[0], P[1], G[0]);
    and (c2_terms[1], P[1], P[0], C_1);
    or  (carry[1], G[1], c2_terms[0], c2_terms[1]);

    and (c3_terms[0], P[2], G[1]);
    and (c3_terms[1], P[2], P[1], G[0]);
    and (c3_terms[2], P[2], P[1], P[0], C_1);
    or  (carry[2], G[2], c3_terms[0], c3_terms[1], c3_terms[2]);

    and (c4_terms[0], P[3], G[2]);
    and (c4_terms[1], P[3], P[2], G[1]);
    and (c4_terms[2], P[3], P[2], P[1], G[0]);
    and (c4_terms[3], P[3], P[2], P[1], P[0], C_1);
    or  (CO, G[3], c4_terms[0], c4_terms[1], c4_terms[2], c4_terms[3]);

    xor sum_bits[3:0](S, P, {carry, C_1});
endmodule
