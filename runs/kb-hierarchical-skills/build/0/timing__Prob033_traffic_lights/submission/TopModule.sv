module TopModule (
    input rst_n,
    input clk,
    input pass_request,
    output reg [7:0] clock,
    output reg red,
    output reg yellow,
    output reg green
);

    parameter idle      = 2'd0,
              s1_red    = 2'd1,
              s2_green  = 2'd2,
              s3_yellow = 2'd3;

    reg [1:0] state;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= s1_red;
            clock <= 8'd10;
        end else if (state == s2_green && pass_request && clock > 8'd10) begin
            clock <= 8'd10;
        end else if (clock == 8'd1) begin
            case (state)
                s1_red: begin
                    state <= s2_green;
                    clock <= 8'd60;
                end
                s2_green: begin
                    state <= s3_yellow;
                    clock <= 8'd5;
                end
                default: begin
                    state <= s1_red;
                    clock <= 8'd10;
                end
            endcase
        end else begin
            clock <= clock - 8'd1;
        end
    end

    always @(*) begin
        red    = 1'b0;
        yellow = 1'b0;
        green  = 1'b0;
        case (state)
            s2_green:  green  = 1'b1;
            s3_yellow: yellow = 1'b1;
            default:   red    = 1'b1;
        endcase
    end

endmodule
