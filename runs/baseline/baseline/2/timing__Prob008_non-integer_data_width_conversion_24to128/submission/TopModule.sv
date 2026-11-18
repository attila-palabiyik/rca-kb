module TopModule(
    input              clk,
    input              rst_n,
    input              valid_in,
    input      [23:0]  data_in,
    output reg         valid_out,
    output reg [127:0] data_out
);
    reg [3:0]   cnt;
    reg [127:0] data_lock;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt       <= 4'd0;
            data_lock <= 128'd0;
            valid_out <= 1'b0;
            data_out  <= 128'd0;
        end else begin
            valid_out <= 1'b0;
            if (valid_in) begin
                cnt       <= cnt + 4'd1;
                data_lock <= {data_lock[103:0], data_in};

                // Sixteen input samples span three output words.
                case (cnt)
                    4'd5: begin
                        data_out  <= {data_lock[119:0], data_in[23:16]};
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
                    default: begin
                    end
                endcase
            end
        end
    end
endmodule
