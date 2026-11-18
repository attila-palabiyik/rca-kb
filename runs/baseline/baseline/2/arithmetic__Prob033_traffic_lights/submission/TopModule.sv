module TopModule (
    input wire rst_n,
    input wire clk,
    input wire pass_request,
    output reg [7:0] clock,
    output reg red,
    output reg yellow,
    output reg green
);

    localparam [7:0] RED_TIME = 8'd10;
    localparam [7:0] GREEN_TIME = 8'd60;
    localparam [7:0] YELLOW_TIME = 8'd5;
    localparam [7:0] PEDESTRIAN_TIME = 8'd10;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            {red, yellow, green} <= 3'b100;
            clock <= RED_TIME;
        end else if (clock == 8'd1) begin
            case ({red, yellow, green})
                3'b100: begin
                    {red, yellow, green} <= 3'b001;
                    clock <= GREEN_TIME;
                end
                3'b001: begin
                    {red, yellow, green} <= 3'b010;
                    clock <= YELLOW_TIME;
                end
                default: begin
                    {red, yellow, green} <= 3'b100;
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
