module TopModule(
    input clk,
    input rst_n,
    input [1:0] wave_choice,
    output reg [4:0] wave
);

    localparam [4:0] PEAK = 5'd20;

    reg [4:0] cnt;
    reg falling;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt <= 5'd0;
            falling <= 1'b0;
            wave <= 5'd0;
        end else begin
            cnt <= 5'd0;
            falling <= 1'b0;

            case (wave_choice)
                2'd0: begin
                    cnt <= (cnt == 5'd19) ? 5'd0 : cnt + 5'd1;
                    wave <= (cnt >= 5'd9 && cnt < 5'd19) ? PEAK : 5'd0;
                end
                2'd1: wave <= (wave == PEAK) ? 5'd0 : wave + 5'd1;
                2'd2: begin
                    if (wave == PEAK || (falling && wave != 5'd0)) begin
                        wave <= wave - 5'd1;
                        falling <= 1'b1;
                    end else begin
                        wave <= wave + 5'd1;
                    end
                end
                default: wave <= 5'd0;
            endcase
        end
    end
endmodule
