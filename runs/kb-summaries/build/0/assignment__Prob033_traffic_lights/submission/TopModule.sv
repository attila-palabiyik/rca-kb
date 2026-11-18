module TopModule (
    input rst_n,
    input clk,
    input pass_request,
    output reg [7:0] clock,
    output reg red,
    output reg yellow,
    output reg green
);

    localparam [7:0] RED_TIME = 8'd10,
                     GREEN_TIME = 8'd60,
                     YELLOW_TIME = 8'd5,
                     REQUEST_TIME = 8'd10;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            {red, yellow, green} <= 3'b100;
            clock <= RED_TIME;
        end else if (clock == 8'd1) begin
            // Change the light and reload its timer on the same edge.
            if (red) begin
                {red, yellow, green} <= 3'b001;
                clock <= GREEN_TIME;
            end else if (green) begin
                {red, yellow, green} <= 3'b010;
                clock <= YELLOW_TIME;
            end else begin
                {red, yellow, green} <= 3'b100;
                clock <= RED_TIME;
            end
        end else if (green && pass_request && clock > REQUEST_TIME) begin
            clock <= REQUEST_TIME;
        end else begin
            clock <= clock - 8'd1;
        end
    end

endmodule
