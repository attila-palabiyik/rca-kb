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
            clock <= 8'd10;
            red <= 1'b1;
            yellow <= 1'b0;
            green <= 1'b0;
        end else if (clock == 8'd1) begin
            if (red) begin
                clock <= 8'd60;
                red <= 1'b0;
                green <= 1'b1;
            end else if (green) begin
                clock <= 8'd5;
                green <= 1'b0;
                yellow <= 1'b1;
            end else begin
                clock <= 8'd10;
                yellow <= 1'b0;
                red <= 1'b1;
            end
        end else if (green && pass_request && clock > 8'd10) begin
            clock <= 8'd10;
        end else begin
            clock <= clock - 8'd1;
        end
    end

endmodule
