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

    localparam [7:0] RED_TIME = 8'd10,
                     GREEN_TIME = 8'd60,
                     YELLOW_TIME = 8'd5,
                     REQUEST_TIME = 8'd10;

    reg [1:0] state;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= s1_red;
            clock <= RED_TIME;
        end else begin
            case (state)
                s1_red: begin
                    if (clock == 8'd1) begin
                        state <= s2_green;
                        clock <= GREEN_TIME;
                    end else begin
                        clock <= clock - 8'd1;
                    end
                end
                s2_green: begin
                    if (clock == 8'd1) begin
                        state <= s3_yellow;
                        clock <= YELLOW_TIME;
                    end else if (pass_request && clock > REQUEST_TIME) begin
                        clock <= REQUEST_TIME;
                    end else begin
                        clock <= clock - 8'd1;
                    end
                end
                s3_yellow: begin
                    if (clock == 8'd1) begin
                        state <= s1_red;
                        clock <= RED_TIME;
                    end else begin
                        clock <= clock - 8'd1;
                    end
                end
                default: begin
                    state <= s1_red;
                    clock <= RED_TIME;
                end
            endcase
        end
    end

    always @(*) begin
        red = !rst_n || state == s1_red;
        yellow = rst_n && state == s3_yellow;
        green = rst_n && state == s2_green;
    end

endmodule
