module TopModule(
    input clk,
    input rst_n,
    input [1:0] wave_choice,
    output reg [4:0] wave
);
    localparam [1:0] SQUARE = 2'd0, SAWTOOTH = 2'd1, TRIANGLE = 2'd2;
    localparam [4:0] PEAK = 5'd20;

    reg [4:0] square_count;
    reg descending;

    wire [4:0] next_square_count = (square_count == 5'd19)
        ? 5'd0 : square_count + 5'd1;
    wire triangle_down = (wave == PEAK) || (descending && wave != 5'd0);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            square_count <= 5'd0;
            descending <= 1'b0;
            wave <= 5'd0;
        end else begin
            square_count <= (wave_choice == SQUARE) ? next_square_count : 5'd0;
            descending <= (wave_choice == TRIANGLE) && triangle_down;

            case (wave_choice)
                SQUARE:   wave <= (next_square_count >= 5'd10) ? PEAK : 5'd0;
                SAWTOOTH: wave <= (wave == PEAK) ? 5'd0 : wave + 5'd1;
                TRIANGLE: wave <= triangle_down ? wave - 5'd1 : wave + 5'd1;
                default:  wave <= 5'd0;
            endcase
        end
    end
endmodule
