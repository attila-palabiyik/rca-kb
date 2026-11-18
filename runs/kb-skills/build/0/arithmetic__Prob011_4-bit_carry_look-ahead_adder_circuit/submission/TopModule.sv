module TopModule(
    input  wire [3:0] A_in,
    input  wire [3:0] B_in,
    input  wire       C_1,
    output wire       CO,
    output wire [3:0] S
);
    wire [3:0] G, P;
    wire [2:0] C;
    wire       c0_p;
    wire [1:0] c1_p;
    wire [2:0] c2_p;
    wire [3:0] c3_p;

    for (genvar i = 0; i < 4; i = i + 1) begin : bit_terms
        and generate_bit(G[i], A_in[i], B_in[i]);
        xor propagate_bit(P[i], A_in[i], B_in[i]);
    end

    // Expand each carry into products of generate and propagate terms.
    and carry0_in(c0_p, P[0], C_1);
    or  carry0(C[0], G[0], c0_p);

    and carry1_g0(c1_p[0], P[1], G[0]);
    and carry1_in(c1_p[1], P[1], P[0], C_1);
    or  carry1(C[1], G[1], c1_p[0], c1_p[1]);

    and carry2_g1(c2_p[0], P[2], G[1]);
    and carry2_g0(c2_p[1], P[2], P[1], G[0]);
    and carry2_in(c2_p[2], P[2], P[1], P[0], C_1);
    or  carry2(C[2], G[2], c2_p[0], c2_p[1], c2_p[2]);

    and carry3_g2(c3_p[0], P[3], G[2]);
    and carry3_g1(c3_p[1], P[3], P[2], G[1]);
    and carry3_g0(c3_p[2], P[3], P[2], P[1], G[0]);
    and carry3_in(c3_p[3], P[3], P[2], P[1], P[0], C_1);
    or  carry3(CO, G[3], c3_p[0], c3_p[1], c3_p[2], c3_p[3]);

    xor sum0(S[0], P[0], C_1);
    xor sum1(S[1], P[1], C[0]);
    xor sum2(S[2], P[2], C[1]);
    xor sum3(S[3], P[3], C[2]);
endmodule
