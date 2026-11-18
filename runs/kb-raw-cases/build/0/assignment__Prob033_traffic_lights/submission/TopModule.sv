module TopModule (
    input rst_n,
    input clk,
    input pass_request,
    output reg [7:0] clock,
    output reg red,
    output reg yellow,
    output reg green
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            {red, yellow, green} <= 3'b100;
            clock <= 8'd10;
        end else if (clock == 8'd1) begin
            if (red) begin
                {red, yellow, green} <= 3'b001;
                clock <= 8'd60;
            end else if (green) begin
                {red, yellow, green} <= 3'b010;
                clock <= 8'd5;
            end else begin
                {red, yellow, green} <= 3'b100;
                clock <= 8'd10;
            end
        end else if (green && pass_request && clock > 8'd10) begin
            clock <= 8'd10;
        end else begin
            clock <= clock - 8'd1;
        end
    end
endmodule
