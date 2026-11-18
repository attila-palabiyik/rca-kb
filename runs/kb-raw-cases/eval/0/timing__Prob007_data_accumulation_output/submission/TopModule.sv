module TopModule(
    input  wire       clk,
    input  wire       rst_n,
    input  wire [7:0] data_in,
    input  wire       valid_a,
    input  wire       ready_b,
    output wire       ready_a,
    output reg        valid_b,
    output reg  [9:0] data_out
);
    reg [1:0] data_cnt;
    wire accept_input = valid_a && ready_a;

    assign ready_a = !valid_b || ready_b;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_cnt <= 2'd0;
            data_out <= 10'd0;
        end else if (accept_input) begin
            data_cnt <= data_cnt + 2'd1;
            if (data_cnt == 2'd0)
                data_out <= {2'b00, data_in};
            else
                data_out <= data_out + {2'b00, data_in};
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            valid_b <= 1'b0;
        else if (accept_input && data_cnt == 2'd3)
            valid_b <= 1'b1;
        else if (valid_b && ready_b)
            valid_b <= 1'b0;
    end
endmodule
