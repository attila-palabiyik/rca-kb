module TopModule (
    input            clk,
    input            rst_n,
    input      [1:0] wave_choice,
    output reg [4:0] wave
);

    localparam [4:0] PEAK = 5'd20;

    reg [4:0] square_count;
    reg triangle_descending;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            square_count        <= 5'd0;
            triangle_descending <= 1'b0;
            wave                <= 5'd0;
        end else begin
            if (wave_choice != 2'd0 || square_count == 5'd20)
                square_count <= 5'd0;
            else
                square_count <= square_count + 5'd1;

            if (wave_choice != 2'd2 || wave == 5'd0)
                triangle_descending <= 1'b0;
            else if (wave == PEAK)
                triangle_descending <= 1'b1;

            case (wave_choice)
                2'd0: wave <= (square_count >= 5'd9 &&
                               square_count < 5'd20) ? PEAK : 5'd0;
                2'd1: wave <= (wave == PEAK) ? 5'd0 : wave + 5'd1;
                2'd2: begin
                    if (wave == 5'd0)
                        wave <= 5'd1;
                    else if (wave == PEAK || triangle_descending)
                        wave <= wave - 5'd1;
                    else
                        wave <= wave + 5'd1;
                end
                default: wave <= 5'd0;
            endcase
        end
    end

endmodule
