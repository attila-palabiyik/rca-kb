module TopModule(
    input clk,
    input rst_n,
    input set,
    input [3:0] set_num,
    output reg [3:0] number,
    output reg zero
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            number <= 4'd0;
        else if (set)
            number <= set_num;
        else
            number <= number + 4'd1;
    end

    always @* begin
        zero = (number == 4'd0);
    end

endmodule
