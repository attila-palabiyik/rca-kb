module TopModule(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       valid_a,
    input  wire       data_a,
    output wire       ready_a,
    output reg        valid_b,
    output reg  [5:0] data_b
);
    reg [4:0] data_r;
    reg [2:0] cnt;

    assign ready_a = 1'b1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_r <= 5'b0;
            cnt     <= 3'd0;
            valid_b <= 1'b0;
            data_b  <= 6'b0;
        end else begin
            valid_b <= 1'b0;
            if (valid_a) begin
                data_r <= {data_a, data_r[4:1]};
                if (cnt == 3'd5) begin
                    cnt     <= 3'd0;
                    valid_b <= 1'b1;
                    data_b  <= {data_a, data_r};
                end else begin
                    cnt <= cnt + 3'd1;
                end
            end
        end
    end
endmodule
