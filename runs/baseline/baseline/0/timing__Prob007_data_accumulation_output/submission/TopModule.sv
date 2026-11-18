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
    reg [9:0] partial_sum;
    wire [9:0] next_sum;

    assign next_sum = partial_sum + {2'b00, data_in};

    // A pending output only blocks the input that would complete the next sum.
    assign ready_a = (data_cnt != 2'd3) || !valid_b || ready_b;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_cnt    <= 2'd0;
            partial_sum <= 10'd0;
            valid_b     <= 1'b0;
            data_out    <= 10'd0;
        end else begin
            if (valid_b && ready_b)
                valid_b <= 1'b0;

            if (valid_a && ready_a) begin
                data_cnt <= data_cnt + 2'd1;
                if (data_cnt == 2'd3) begin
                    data_out    <= next_sum;
                    valid_b     <= 1'b1;
                    partial_sum <= 10'd0;
                end else begin
                    partial_sum <= next_sum;
                end
            end
        end
    end
endmodule
