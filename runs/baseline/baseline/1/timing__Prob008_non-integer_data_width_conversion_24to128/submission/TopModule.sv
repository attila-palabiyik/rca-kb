module TopModule(
    input              clk,
    input              rst_n,
    input              valid_in,
    input       [23:0] data_in,
    output reg         valid_out,
    output reg [127:0] data_out
);
    reg   [3:0] cnt;
    reg [119:0] data_lock;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt       <= 4'd0;
            data_lock <= 120'd0;
            valid_out <= 1'b0;
            data_out  <= 128'd0;
        end else begin
            valid_out <= 1'b0;
            if (valid_in) begin
                cnt       <= cnt + 4'd1;
                data_lock <= {data_lock[95:0], data_in};

                // Sixteen 24-bit inputs produce three 128-bit outputs.
                // Each boundary consumes 8, 16, or 24 bits of the current input.
                case (cnt)
                    4'd5: begin
                        data_out  <= {data_lock, data_in[23:16]};
                        valid_out <= 1'b1;
                    end
                    4'd10: begin
                        data_out  <= {data_lock[111:0], data_in[23:8]};
                        valid_out <= 1'b1;
                    end
                    4'd15: begin
                        data_out  <= {data_lock[103:0], data_in};
                        valid_out <= 1'b1;
                    end
                endcase
            end
        end
    end
endmodule
