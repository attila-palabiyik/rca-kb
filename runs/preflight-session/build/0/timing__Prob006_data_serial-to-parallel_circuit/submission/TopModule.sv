module TopModule (
    input            clk,
    input            rst_n,
    input            valid_a,
    input            data_a,
    output           ready_a,
    output reg       valid_b,
    output reg [5:0] data_b
);
    reg [5:0] data_r;
    reg [2:0] cnt;
    wire [5:0] shifted_data = {data_a, data_r[5:1]};
    wire word_complete = valid_a && (cnt == 3'd5);

    assign ready_a = 1'b1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt     <= 3'd0;
            data_r  <= 6'd0;
            valid_b <= 1'b0;
            data_b  <= 6'd0;
        end else begin
            valid_b <= word_complete;

            if (valid_a) begin
                data_r <= shifted_data;
                cnt <= word_complete ? 3'd0 : cnt + 3'd1;
            end

            if (word_complete)
                data_b <= shifted_data;
        end
    end
endmodule
