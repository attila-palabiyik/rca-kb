module TopModule (
    input rst_n,
    input clk,
    input pass_request,
    output reg [7:0] clock,
    output reg red,
    output reg yellow,
    output reg green
);

    localparam [1:0] RED = 2'd0, GREEN = 2'd1, YELLOW = 2'd2;

    reg [1:0] state;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= RED;
            clock <= 8'd10;
        end else if (clock == 8'd1) begin
            case (state)
                RED: begin
                    state <= GREEN;
                    clock <= 8'd60;
                end
                GREEN: begin
                    state <= YELLOW;
                    clock <= 8'd5;
                end
                default: begin
                    state <= RED;
                    clock <= 8'd10;
                end
            endcase
        end else if (state == GREEN && pass_request && clock > 8'd10) begin
            clock <= 8'd10;
        end else begin
            clock <= clock - 8'd1;
        end
    end

    always @* begin
        red = (state == RED);
        yellow = (state == YELLOW);
        green = (state == GREEN);
    end

endmodule
