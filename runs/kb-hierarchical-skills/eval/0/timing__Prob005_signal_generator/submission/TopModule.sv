module TopModule(
    input clk,
    input rst_n,
    input [1:0] wave_choice,
    output reg [4:0] wave
);

    localparam [4:0] PEAK = 5'd20;

    reg [4:0] cnt;
    reg triangle_rising;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            cnt <= 5'd0;
        else if (wave_choice != 2'd0 || cnt == 5'd19)
            cnt <= 5'd0;
        else
            cnt <= cnt + 5'd1;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            triangle_rising <= 1'b0;
        else if (wave_choice != 2'd2 || wave == PEAK)
            triangle_rising <= 1'b0;
        else if (wave == 5'd0)
            triangle_rising <= 1'b1;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            wave <= 5'd0;
        else begin
            case (wave_choice)
                2'd0: wave <= (cnt >= 5'd9 && cnt < 5'd19) ? PEAK : 5'd0;
                2'd1: wave <= (wave == PEAK) ? 5'd0 : wave + 5'd1;
                2'd2: begin
                    if (wave == 5'd0 || (wave != PEAK && triangle_rising))
                        wave <= wave + 5'd1;
                    else
                        wave <= wave - 5'd1;
                end
                default: wave <= 5'd0;
            endcase
        end
    end

endmodule
