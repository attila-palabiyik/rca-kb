module TopModule(
    input clk,
    input rst_n,
    input [7:0] a,
    input [7:0] b,
    input [7:0] c,
    output [7:0] d
);

    wire [7:0] c_out1;
    reg [7:0] c1;

    slave_mod s1(
        .clk(clk),
        .rst_n(rst_n),
        .data_a(a),
        .data_b(b),
        .c_out(c_out1)
    );

    // Sample c alongside the first comparison.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            c1 <= 8'b0;
        else
            c1 <= c;
    end

    slave_mod s2(
        .clk(clk),
        .rst_n(rst_n),
        .data_a(c_out1),
        .data_b(c1),
        .c_out(d)
    );

endmodule

module slave_mod(
    input clk,
    input rst_n,
    input [7:0] data_a,
    input [7:0] data_b,
    output reg [7:0] c_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            c_out <= 8'b0;
        else if (data_a > data_b)
            c_out <= data_b;
        else
            c_out <= data_a;
    end

endmodule
