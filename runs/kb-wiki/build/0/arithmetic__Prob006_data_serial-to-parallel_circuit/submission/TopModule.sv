module TopModule(
    input        clk,
    input        rst_n,
    input        valid_a,
    input        data_a,
    output wire  ready_a,
    output reg   valid_b,
    output reg [5:0] data_b
);
    reg [5:0] data_r;
    reg [2:0] cnt;

    assign ready_a = 1'b1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt <= 3'd0;
            data_r <= 6'b0;
            data_b <= 6'b0;
            valid_b <= 1'b0;
        end else begin
            valid_b <= 1'b0;
            if (valid_a) begin
                data_r <= {data_a, data_r[5:1]};
                if (cnt == 3'd5) begin
                    cnt <= 3'd0;
                    data_b <= {data_a, data_r[5:1]};
                    valid_b <= 1'b1;
                end else begin
                    cnt <= cnt + 3'd1;
                end
            end
        end
    end
endmodule
