module TopModule (
    input clk,
    input rst_n,
    input [1:0] wave_choice,
    output reg [4:0] wave
);

    localparam [4:0] PEAK = 5'd20;

    reg [4:0] square_count;
    reg descending;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            square_count <= 5'd0;
            descending <= 1'b0;
            wave <= 5'd0;
        end else begin
            if (wave_choice != 2'd0)
                square_count <= 5'd0;
            if (wave_choice != 2'd2)
                descending <= 1'b0;

            case (wave_choice)
                2'd0: begin
                    if (square_count == 5'd19)
                        square_count <= 5'd0;
                    else
                        square_count <= square_count + 5'd1;

                    // The output rises on the tenth clock and falls on the twentieth.
                    if (square_count >= 5'd9 && square_count < 5'd19)
                        wave <= PEAK;
                    else
                        wave <= 5'd0;
                end
                2'd1: begin
                    if (wave == PEAK)
                        wave <= 5'd0;
                    else
                        wave <= wave + 5'd1;
                end
                2'd2: begin
                    if (wave == PEAK) begin
                        wave <= PEAK - 5'd1;
                        descending <= 1'b1;
                    end else if (wave == 5'd0) begin
                        wave <= 5'd1;
                        descending <= 1'b0;
                    end else if (descending) begin
                        wave <= wave - 5'd1;
                    end else begin
                        wave <= wave + 5'd1;
                    end
                end
                default: wave <= 5'd0;
            endcase
        end
    end
endmodule
