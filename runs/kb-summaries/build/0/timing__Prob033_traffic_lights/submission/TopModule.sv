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
    localparam [2:0] GREEN  = 3'b010;
    localparam [2:0] YELLOW = 3'b001;

    localparam [7:0] RED_TIME        = 8'd10;
    localparam [7:0] GREEN_TIME      = 8'd60;
    localparam [7:0] YELLOW_TIME     = 8'd5;
    localparam [7:0] PEDESTRIAN_TIME = 8'd10;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            {red, green, yellow} <= RED;
            clock <= RED_TIME;
        end else if (clock == 8'd1) begin
            case ({red, green, yellow})
                RED: begin
                    {red, green, yellow} <= GREEN;
                    clock <= GREEN_TIME;
                end
                GREEN: begin
                    {red, green, yellow} <= YELLOW;
                    clock <= YELLOW_TIME;
                end
                default: begin
                    {red, green, yellow} <= RED;
                    clock <= RED_TIME;
                end
            endcase
        end else if (green && pass_request && clock > PEDESTRIAN_TIME) begin
            clock <= PEDESTRIAN_TIME;
        end else begin
            clock <= clock - 8'd1;
        end
    end

endmodule
