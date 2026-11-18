module TopModule(
    input              clk,
    input              rst_n,
    input              valid_in,
    input      [23:0]  data_in,
    output reg         valid_out,
    output reg [127:0] data_out
);
    // Sixteen input words contain exactly three output words.
    reg [3:0]   cnt;
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

                // Take the oldest unconsumed bits first and leave any
                // remaining low bits of data_in in data_lock.
                case (cnt)
                    4'd5:  data_out <= {data_lock, data_in[23:16]};
                    4'd10: data_out <= {data_lock[111:0], data_in[23:8]};
                    4'd15: data_out <= {data_lock[103:0], data_in};
                    default: ;
                endcase
                valid_out <= (cnt == 4'd5 || cnt == 4'd10 || cnt == 4'd15);
            end
        end
    end
endmodule
