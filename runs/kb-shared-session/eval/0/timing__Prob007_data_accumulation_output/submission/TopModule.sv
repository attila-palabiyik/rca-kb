module TopModule(
    input clk,
    input rst_n,
    input [7:0] data_in,
    input valid_a,
    input ready_b,
    output wire ready_a,
    output reg valid_b,
    output reg [9:0] data_out
);
    reg [1:0] data_cnt;
    wire accept_input = valid_a && ready_a;

    assign ready_a = !valid_b || ready_b;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_cnt <= 2'd0;
            valid_b <= 1'b0;
            data_out <= 10'd0;
        end else begin
            if (accept_input) begin
                data_cnt <= data_cnt + 2'd1;
                if (data_cnt == 2'd0)
                    data_out <= {2'b00, data_in};
                else
                    data_out <= data_out + {2'b00, data_in};
            end

            if (accept_input && data_cnt == 2'd3)
                valid_b <= 1'b1;
            else if (ready_b)
                valid_b <= 1'b0;
        end
    end
endmodule
