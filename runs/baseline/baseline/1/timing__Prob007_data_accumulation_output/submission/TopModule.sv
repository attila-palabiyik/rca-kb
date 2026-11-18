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

assign ready_a = !valid_b || ready_b;

always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        data_cnt <= 2'd0;
        valid_b  <= 1'b0;
        data_out <= 10'd0;
    end else begin
        if (valid_b && ready_b)
            valid_b <= 1'b0;

        if (valid_a && ready_a) begin
            data_cnt <= data_cnt + 2'd1;
            if (data_cnt == 2'd0)
                data_out <= {2'b00, data_in};
            else
                data_out <= data_out + {2'b00, data_in};

            if (data_cnt == 2'd3)
                valid_b <= 1'b1;
        end
    end
end

endmodule
