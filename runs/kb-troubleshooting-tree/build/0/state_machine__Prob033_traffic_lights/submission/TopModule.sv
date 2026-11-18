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
    localparam [2:0] YELLOW = 3'b010;
    localparam [2:0] GREEN  = 3'b001;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            {red, yellow, green} <= RED;
            clock <= 8'd10;
        end else begin
            clock <= clock - 8'd1;
            case ({red, yellow, green})
                RED: begin
                    if (clock == 8'd1) begin
                        {red, yellow, green} <= GREEN;
                        clock <= 8'd60;
                    end
                end
                GREEN: begin
                    if (clock == 8'd1) begin
                        {red, yellow, green} <= YELLOW;
                        clock <= 8'd5;
                    end else if (pass_request && clock > 8'd10) begin
                        clock <= 8'd10;
                    end
                end
                YELLOW: begin
                    if (clock == 8'd1) begin
                        {red, yellow, green} <= RED;
                        clock <= 8'd10;
                    end
                end
                default: begin
                    {red, yellow, green} <= RED;
                    clock <= 8'd10;
                end
            endcase
        end
    end
endmodule
