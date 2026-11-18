module TopModule (
    input clk,
    input rst_n,
    input [1:0] wave_choice,
    output reg [4:0] wave
);

    localparam [4:0] WAVE_MAX = 5'd20;

    reg [4:0] cnt;
    reg rising;
    wire triangle_rises;

    assign triangle_rises = wave == 5'd0 || (rising && wave != WAVE_MAX);

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
            rising <= 1'b0;
        else
            rising <= wave_choice == 2'd2 && triangle_rises;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            wave <= 5'd0;
        else
            case (wave_choice)
                2'd0: wave <= (cnt >= 5'd9 && cnt < 5'd19) ? WAVE_MAX : 5'd0;
                2'd1: wave <= (wave == WAVE_MAX) ? 5'd0 : wave + 5'd1;
                2'd2: wave <= triangle_rises ? wave + 5'd1 : wave - 5'd1;
                default: wave <= 5'd0;
            endcase
    end
endmodule
