module TopModule(
    input clk,
    input rst_n,
    input [1:0] wave_choice,
    output reg [4:0] wave
);

    localparam [4:0] PEAK = 5'd20;
    reg [4:0] cnt;
    reg descending;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt <= 5'd0;
            descending <= 1'b0;
            wave <= 5'd0;
        end else begin
            cnt <= 5'd0;
            descending <= 1'b0;

            case (wave_choice)
                2'd0: begin
                    if (cnt != 5'd20)
                        cnt <= cnt + 5'd1;

                    if (cnt >= 5'd9 && cnt < 5'd20)
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
                    if (wave != 5'd0 && (descending || wave == PEAK)) begin
                        wave <= wave - 5'd1;
                        descending <= 1'b1;
                    end else begin
                        wave <= wave + 5'd1;
                    end
                end
                default: wave <= 5'd0;
            endcase
        end
    end
endmodule
