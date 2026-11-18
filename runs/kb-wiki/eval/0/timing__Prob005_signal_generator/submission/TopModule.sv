module TopModule(
    input clk,
    input rst_n,
    input [1:0] wave_choice,
    output reg [4:0] wave
);

    localparam [1:0] SQUARE = 2'd0, SAWTOOTH = 2'd1, TRIANGLE = 2'd2;
    localparam [4:0] PEAK = 5'd20;

    reg [4:0] square_count;
    reg triangle_falling;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            square_count <= 5'd0;
        else if (wave_choice != SQUARE || square_count == 5'd19)
            square_count <= 5'd0;
        else
            square_count <= square_count + 5'd1;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            triangle_falling <= 1'b0;
        else if (wave_choice != TRIANGLE || wave == 5'd0)
            triangle_falling <= 1'b0;
        else if (wave == PEAK)
            triangle_falling <= 1'b1;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            wave <= 5'd0;
        else begin
            case (wave_choice)
                SQUARE: wave <= (square_count >= 5'd9 && square_count < 5'd19)
                                ? PEAK : 5'd0;
                SAWTOOTH: wave <= (wave == PEAK) ? 5'd0 : wave + 5'd1;
                TRIANGLE: begin
                    if (wave == 5'd0)
                        wave <= 5'd1;
                    else if (wave == PEAK || triangle_falling)
                        wave <= wave - 5'd1;
                    else
                        wave <= wave + 5'd1;
                end
                default: wave <= 5'd0;
            endcase
        end
    end

endmodule
