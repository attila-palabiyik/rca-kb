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

    slave_mod first_min(
        .clk(clk),
        .rst_n(rst_n),
        .data_a(a),
        .data_b(b),
        .c_out(min_ab)
    );

    // Capture c on the same edge that captures the minimum of a and b.
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            c_delayed <= 8'b0;
        else
            c_delayed <= c;
    end

    slave_mod second_min(
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
            c_out <= 8'b0;
        else if (data_a > data_b)
            c_out <= data_b;
        else
            c_out <= data_a;
    end
endmodule
