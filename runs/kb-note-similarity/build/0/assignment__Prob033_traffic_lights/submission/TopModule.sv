module TopModule (
    input rst_n,
    input clk,
    input pass_request,
    output reg [7:0] clock,
    output reg red,
    output reg yellow,
    output reg green
);

    localparam [2:0] RED = 3'b100,
                     GREEN = 3'b010,
                     YELLOW = 3'b001;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            {red, green, yellow} <= RED;
            clock <= 8'd10;
        end else if (clock == 8'd1) begin
            case ({red, green, yellow})
                RED: begin
                    {red, green, yellow} <= GREEN;
                    clock <= 8'd60;
                end
                GREEN: begin
                    {red, green, yellow} <= YELLOW;
                    clock <= 8'd5;
                end
                YELLOW: begin
                    {red, green, yellow} <= RED;
                    clock <= 8'd10;
                end
            endcase
        end else if (green && pass_request && clock > 8'd10) begin
            clock <= 8'd10;
        end else begin
            clock <= clock - 8'd1;
        end
    end

endmodule
