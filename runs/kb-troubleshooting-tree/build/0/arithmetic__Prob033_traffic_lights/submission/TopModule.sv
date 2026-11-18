module TopModule (
    input rst_n,
    input clk,
    input pass_request,
    output reg [7:0] clock,
    output reg red,
    output reg yellow,
    output reg green
);
    localparam [2:0] RED    = 3'b100;
    localparam [2:0] GREEN  = 3'b001;
    localparam [2:0] YELLOW = 3'b010;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            {red, yellow, green} <= RED;
            clock <= 8'd10;
        end else if (clock == 8'd1) begin
            // Change the light and reload its timer on the same edge.
            case ({red, yellow, green})
                RED: begin
                    {red, yellow, green} <= GREEN;
                    clock <= 8'd60;
                end
                GREEN: begin
                    {red, yellow, green} <= YELLOW;
                    clock <= 8'd5;
                end
                default: begin
                    {red, yellow, green} <= RED;
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
