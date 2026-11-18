module TopModule (
    input rst_n,
    input clk,
    input pass_request,
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
            {red, yellow, green, clock} <= {3'b100, RED_TIME};
        end else if (clock == 8'd1) begin
            case ({red, yellow, green})
                3'b100: {red, yellow, green, clock} <= {3'b001, GREEN_TIME};
                3'b001: {red, yellow, green, clock} <= {3'b010, YELLOW_TIME};
                default: {red, yellow, green, clock} <= {3'b100, RED_TIME};
            endcase
        end else if (green && pass_request && clock > PEDESTRIAN_TIME) begin
            clock <= PEDESTRIAN_TIME;
        end else begin
            clock <= clock - 8'd1;
        end
    end
endmodule
