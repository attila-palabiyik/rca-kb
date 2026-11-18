module TopModule(
    input clk,
    input rst_n,
    input [1:0] wave_choice,
    output reg [4:0] wave
);

    localparam [4:0] PEAK = 5'd20;

    reg [4:0] cnt;
    reg descending;
    wire step_down = (wave == PEAK) || (descending && wave != 5'd0);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wave <= 5'd0;
            cnt <= 5'd0;
            descending <= 1'b0;
        end else begin
            cnt <= 5'd0;
            descending <= 1'b0;

            case (wave_choice)
                2'd0: begin
                    cnt <= (cnt == PEAK) ? 5'd0 : cnt + 5'd1;
                    wave <= (cnt >= 5'd9 && cnt < PEAK) ? PEAK : 5'd0;
                end
                2'd1: begin
                    wave <= (wave == PEAK) ? 5'd0 : wave + 5'd1;
                end
                2'd2: begin
                    descending <= step_down;
                    wave <= step_down ? wave - 5'd1 : wave + 5'd1;
                end
                default: wave <= 5'd0;
            endcase
        end
    end
endmodule
