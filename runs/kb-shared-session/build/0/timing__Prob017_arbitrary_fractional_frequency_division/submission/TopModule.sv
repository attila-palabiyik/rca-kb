module TopModule(
    input wire clk_in,
    input wire rst,
    output wire clk_out
);
    parameter M_N = 8'd87;
    parameter c89 = 8'd24;
    parameter div_e = 5'd8;
    parameter div_o = 5'd9;

    localparam MAX_DIV = (div_e > div_o) ? div_e : div_o;
    localparam PERIOD_WIDTH = $clog2(MAX_DIV + 1);
    localparam FRAME_WIDTH = (M_N > 1) ? $clog2(M_N) : 1;

    reg [PERIOD_WIDTH-1:0] clk_cnt;
    reg [FRAME_WIDTH-1:0] cyc_cnt;
    reg clk_out_r;

    // The switch point and frame end fall on output period boundaries.
    wire [PERIOD_WIDTH-1:0] period = (cyc_cnt < c89) ? div_e : div_o;

    always @(posedge clk_in or negedge rst) begin
        if (!rst) begin
            clk_cnt <= 0;
            cyc_cnt <= 0;
            clk_out_r <= 1'b0;
        end else begin
            clk_cnt <= (clk_cnt == period - 1'b1) ? 0 : clk_cnt + 1'b1;
            cyc_cnt <= (cyc_cnt == M_N - 1'b1) ? 0 : cyc_cnt + 1'b1;
            clk_out_r <= (clk_cnt < (period >> 1));
        end
    end

    assign clk_out = clk_out_r;
endmodule
