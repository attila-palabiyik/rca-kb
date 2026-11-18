module TopModule(
     input  wire clk_in,
     input  wire rst,
     output wire clk_out
);
    parameter M_N = 8'd87;
    parameter c89 = 8'd24;  // Number of input cycles using div_e
    parameter div_e = 5'd8;
    parameter div_o = 5'd9;

    localparam MAX_PERIOD = (div_e > div_o) ? div_e : div_o;
    localparam CLK_CNT_WIDTH = (MAX_PERIOD > 1) ? $clog2(MAX_PERIOD) : 1;
    localparam CYC_CNT_WIDTH = (M_N > 1) ? $clog2(M_N) : 1;

    reg [CLK_CNT_WIDTH-1:0] clk_cnt;
    reg [CYC_CNT_WIDTH-1:0] cyc_cnt;
    reg clk_out_r;

    // Both sections contain whole output periods: 24 = 3*8, 63 = 7*9.
    wire use_odd_period = (cyc_cnt >= c89);
    wire [CLK_CNT_WIDTH:0] period = use_odd_period ? div_o : div_e;

    always @(posedge clk_in or negedge rst) begin
        if (!rst) begin
            clk_cnt <= 0;
            cyc_cnt <= 0;
            clk_out_r <= 1'b0;
        end else begin
            clk_cnt <= (clk_cnt == period - 1) ? 0 : clk_cnt + 1'b1;
            cyc_cnt <= (cyc_cnt == M_N - 1) ? 0 : cyc_cnt + 1'b1;
            clk_out_r <= (clk_cnt < (period >> 1));
        end
    end

    assign clk_out = clk_out_r;
endmodule
