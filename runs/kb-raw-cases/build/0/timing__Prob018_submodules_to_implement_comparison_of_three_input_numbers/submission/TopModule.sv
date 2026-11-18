module TopModule(
    input clk,
    input rst_n,
    input [7:0] a,
    input [7:0] b,
    input [7:0] c,
    output [7:0] d
);

    wire [7:0] min_ab;
    reg [7:0] c_delayed;

    slave_mod compare_ab(
        .clk(clk),
        .rst_n(rst_n),
        .data_a(a),
        .data_b(b),
        .c_out(min_ab)
    );

    // Capture c alongside the first comparison so both stages use the same sample.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            c_delayed <= 8'd0;
        else
            c_delayed <= c;
    end

    slave_mod compare_with_c(
        .clk(clk),
        .rst_n(rst_n),
        .data_a(min_ab),
        .data_b(c_delayed),
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
            c_out <= 8'd0;
        else if (data_a > data_b)
            c_out <= data_b;
        else
            c_out <= data_a;
    end
endmodule
