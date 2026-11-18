module TopModule (
    input rst_n,
    input clk,
    input pass_request,
    output reg [7:0] clock,
    output reg red,
    output reg yellow,
    output reg green
);

    localparam [2:0] RED = 3'b100, GREEN = 3'b001, YELLOW = 3'b010;
    localparam [7:0] RED_TIME = 8'd10, GREEN_TIME = 8'd60, YELLOW_TIME = 8'd5;
    localparam [7:0] REQUEST_TIME = 8'd10;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            {red, yellow, green} <= RED;
            clock <= RED_TIME;
        end else if (clock == 8'd1) begin
            case ({red, yellow, green})
                RED: begin
                    {red, yellow, green} <= GREEN;
                    clock <= GREEN_TIME;
                end
                GREEN: begin
                    {red, yellow, green} <= YELLOW;
                    clock <= YELLOW_TIME;
                end
                default: begin
                    {red, yellow, green} <= RED;
                    clock <= RED_TIME;
                end
            endcase
        end else if (green && pass_request && clock > REQUEST_TIME) begin
            clock <= REQUEST_TIME;
        end else begin
            clock <= clock - 8'd1;
        end
    end

endmodule
