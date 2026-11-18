module TopModule(
    input clk,
    input rst_n,
    input [1:0] wave_choice,
    output reg [4:0] wave
);

    localparam [4:0] WAVE_MAX = 5'd20;

    reg [4:0] cnt;
    reg descending;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt <= 5'd0;
            descending <= 1'b0;
            wave <= 5'd0;
        end else begin
            if (wave_choice != 2'd0 || cnt == 5'd20)
                cnt <= 5'd0;
            else
                cnt <= cnt + 5'd1;

            if (wave_choice != 2'd2 || wave == 5'd0)
                descending <= 1'b0;
            else if (wave == WAVE_MAX)
                descending <= 1'b1;

            case (wave_choice)
                2'd0: wave <= (cnt >= 5'd9 && cnt < 5'd20) ? WAVE_MAX : 5'd0;
                2'd1: wave <= (wave == WAVE_MAX) ? 5'd0 : wave + 5'd1;
                2'd2: begin
                    if (wave == 5'd0)
                        wave <= 5'd1;
                    else if (wave == WAVE_MAX || descending)
                        wave <= wave - 5'd1;
                    else
                        wave <= wave + 5'd1;
                end
                default: wave <= 5'd0;
            endcase
        end
    end
endmodule
