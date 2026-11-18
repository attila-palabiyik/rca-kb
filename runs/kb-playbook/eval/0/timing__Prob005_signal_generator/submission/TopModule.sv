module TopModule(
    input clk,
    input rst_n,
    input [1:0] wave_choice,
    output reg [4:0] wave
);
    localparam [4:0] PEAK = 5'd20;

    reg [4:0] cnt;
    reg descending;
    wire triangle_down = (wave == PEAK) || (descending && wave != 5'd0);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt <= 5'd0;
            descending <= 1'b0;
            wave <= 5'd0;
        end else begin
            if (wave_choice != 2'd0 || cnt == 5'd19)
                cnt <= 5'd0;
            else
                cnt <= cnt + 5'd1;

            descending <= (wave_choice == 2'd2) && triangle_down;

            case (wave_choice)
                2'd0: begin
                    if (cnt == 5'd9)
                        wave <= PEAK;
                    else if (cnt == 5'd19)
                        wave <= 5'd0;
                end
                2'd1: wave <= (wave == PEAK) ? 5'd0 : wave + 5'd1;
                2'd2: wave <= triangle_down ? wave - 5'd1 : wave + 5'd1;
                default: wave <= 5'd0;
            endcase
        end
    end
endmodule
