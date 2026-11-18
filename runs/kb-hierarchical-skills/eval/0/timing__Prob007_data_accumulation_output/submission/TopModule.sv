module TopModule(
    input            clk,
    input            rst_n,
    input      [7:0] data_in,
    input            valid_a,
    input            ready_b,
    output           ready_a,
    output reg       valid_b,
    output reg [9:0] data_out
);
    reg [1:0] data_cnt;
    wire accept_input;

    assign ready_a = !valid_b || ready_b;
    assign accept_input = valid_a && ready_a;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_cnt <= 2'd0;
        else if (accept_input)
            data_cnt <= data_cnt + 2'd1;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            valid_b <= 1'b0;
        else if (accept_input && data_cnt == 2'd3)
            valid_b <= 1'b1;
        else if (ready_b)
            valid_b <= 1'b0;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_out <= 10'd0;
        else if (accept_input) begin
            if (data_cnt == 2'd0)
                data_out <= {2'b00, data_in};
            else
                data_out <= data_out + {2'b00, data_in};
        end
    end
endmodule
