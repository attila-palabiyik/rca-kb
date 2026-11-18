module TopModule (
    input rst_n,
    input clk,
    input pass_request,
    output reg [7:0] clock,
    output reg red,
    output reg yellow,
    output reg green
);

    parameter idle = 2'd0,
              s1_red = 2'd1,
              s2_green = 2'd2,
              s3_yellow = 2'd3;

    reg [1:0] state;

    assign red = (state == s1_red);
    assign yellow = (state == s3_yellow);
    assign green = (state == s2_green);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= s1_red;
            clock <= 8'd10;
        end else begin
            case (state)
                s1_red: begin
                    if (clock == 8'd1) begin
                        state <= s2_green;
                        clock <= 8'd60;
                    end else begin
                        clock <= clock - 8'd1;
                    end
                end

                s2_green: begin
                    if (clock == 8'd1) begin
                        state <= s3_yellow;
                        clock <= 8'd5;
                    end else if (pass_request && clock > 8'd10) begin
                        clock <= 8'd10;
                    end else begin
                        clock <= clock - 8'd1;
                    end
                end

                s3_yellow: begin
                    if (clock == 8'd1) begin
                        state <= s1_red;
                        clock <= 8'd10;
                    end else begin
                        clock <= clock - 8'd1;
                    end
                end

                default: begin
                    state <= s1_red;
                    clock <= 8'd10;
                end
            endcase
        end
    end

endmodule
